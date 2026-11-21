#!/usr/bin/env python3
"""Local rootfs-selection and Ansible integration tests; no real devices."""
import argparse
import os
import pathlib
import subprocess
import tempfile
import time
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--image', required=True, help='local OpenWrt fixture with exporter packages')
parser.add_argument('--source-volume', default='openwrt-mikrotik-root-openwrt')
parser.add_argument('--build-image', default='openwrt-mikrotik')
parser.add_argument('--ansible-repo', type=pathlib.Path)
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parents[1]
repo = args.ansible_repo or root.parent / 'ansible-openwrt'
name = 'prometheus-simple-' + uuid.uuid4().hex[:8]
network = name + '-net'
service = '/etc/init.d/prometheus-node-exporter-lua'


def docker(*argv, check=True):
    result = subprocess.run(['docker', *map(str, argv)], text=True, capture_output=True)
    if check and result.returncode:
        raise RuntimeError(f'Docker {argv}: {result.stdout} {result.stderr}')
    return result


def run(script, check=True):
    return docker('exec', name, 'sh', '-ec', script, check=check)


def wait_ready():
    end = time.monotonic() + 45
    while time.monotonic() < end:
        if run('ifstatus lan | grep -q "172.29.244.2"', False).returncode == 0:
            return
        time.sleep(1)
    raise AssertionError('netifd not ready')


def listening():
    return run("netstat -lnt | awk '$4 ~ /:9100$/ { found=1 } END { exit !found }'", False).returncode == 0


def expect_listener(wanted):
    end = time.monotonic() + 20
    while time.monotonic() < end:
        if listening() == wanted:
            return
        time.sleep(.5)
    raise AssertionError(f'listener should be {wanted}: ' + run('logread | tail -15', False).stdout)


def peer(ip):
    return docker('run', '--rm', '--network', network, '--ip', ip,
                  '--entrypoint', 'sh', 'postgres:17-alpine', '-ec',
                  'wget -T 2 -qO /tmp/metrics "http://172.29.244.2:9100/metrics?collect=loadavg" && '
                  'grep -q "^node_load1 " /tmp/metrics', check=False).returncode


with tempfile.TemporaryDirectory(prefix='prometheus-simple-') as folder:
    work = pathlib.Path(folder)
    # Render the unmodified upstream init enable/disable loop with GNU make.
    (work / 'build-test.py').write_text('''from pathlib import Path
import subprocess
p=Path('/work')
rootfs=Path('/source/include/rootfs.mk').read_text()
assert 'prometheus-node-exporter-lua' not in Path('/repo/docker-scripts/firmware.sh').read_text()
start=rootfs.index('\\t\\tfor script in ./etc/init.d/*; do')
end=rootfs.index('done || true',start)+len('done || true')
loop=rootfs[start:end].replace('$$(command -v bash)', '/bin/sh')
(p/'selection.mk').write_text('define select_services\\n'+loop+'\\nendef\\nall:\\n\\t$(call select_services,/, ,other-disabled-service)\\n')
result=subprocess.run(['/usr/bin/make','-s','-n','-f',str(p/'selection.mk')],text=True,capture_output=True,check=True)
(p/'selection.sh').write_text('cd /\\n'+result.stdout)
(p/'exporter.config').write_text(Path('/source/feeds/packages/utils/prometheus-node-exporter-lua/files/etc/config/prometheus-node-exporter-lua').read_text())
''')
    docker('run', '--rm', '--network', 'none', '--entrypoint', 'python3',
           '-v', args.source_volume + ':/source:ro', '-v', str(root) + ':/repo:ro',
           '-v', folder + ':/work', args.build_image, '/work/build-test.py')
    print('PASS firmware uses upstream service selection without exporter override', flush=True)
    try:
        docker('network', 'create', '--internal', '--subnet', '172.29.244.0/24', network)
        docker('run', '-d', '--name', name, '--label', 'openwrt-monitoring-test=true',
               '--network', network, '--ip', '172.29.244.2', '--cap-add', 'NET_ADMIN',
               '--cap-add', 'SYS_ADMIN', '--tmpfs', '/tmp', args.image, '/sbin/init')
        run('for n in $(seq 1 30); do ubus list network.interface.lan | grep -q network.interface.lan && exit 0; sleep 1; done; exit 1')
        run(service + ' stop')
        # Normalize the cached fixture to the current native-rule baseline.
        run('uci -q delete firewall.prometheus_input || true; uci commit firewall; '
            'rm -f /etc/prometheus-input.nft /usr/libexec/prometheus-firewall-guard')
        stock = run('sha256sum ' + service).stdout
        assert 'startup guard' not in run('cat ' + service).stdout
        run("printf '#!/bin/sh /etc/rc.common\\nSTART=98\\n' >/etc/init.d/other-disabled-service; chmod +x /etc/init.d/other-disabled-service")
        docker('cp', work / 'selection.sh', name + ':/selection.sh')
        docker('cp', work / 'exporter.config', name + ':/etc/config/prometheus-node-exporter-lua')
        run('sh /selection.sh')
        assert run(service + ' enabled', False).returncode == 0
        assert run('/etc/init.d/other-disabled-service enabled', False).returncode != 0
        run('rm /etc/init.d/other-disabled-service')
        assert run('/etc/init.d/firewall enabled', False).returncode == 0
        assert run('sha256sum ' + service).stdout == stock
        print('PASS upstream rootfs loop enables exporter and keeps stock init unchanged', flush=True)
        run("uci set network.lan=interface; uci set network.lan.device=eth0; uci set network.lan.proto=static; "
            "uci set network.lan.netmask=255.255.255.0; uci set network.lan.ipaddr=172.29.244.2; "
            "uci commit network; /etc/init.d/network restart")
        docker('restart', name); wait_ready(); expect_listener(True)
        assert run(service + ' enabled', False).returncode == 0
        run('wget -qO /tmp/metrics "http://127.0.0.1:9100/metrics?collect=loadavg"; grep -q "^node_load1 " /tmp/metrics')
        assert peer('172.29.244.3') != 0
        print('PASS fresh image starts exporter on loopback after reboot', flush=True)
        # Actual sysupgrade backup records disabled services. Replay that saved
        # state over the upstream image defaults, without flashing any device.
        for enabled in (True, False):
            run(service + (' enable' if enabled else ' disable'))
            run('mkdir -p /test-state; sysupgrade -b /test-state/backup.tgz; tar xzf /test-state/backup.tgz -C /test-state')
            state = run('cat /test-state/etc/uci-defaults/10_disable_services').stdout
            assert (service + ' disable' in state) == (not enabled)
            run('sh /selection.sh; sh /test-state/etc/uci-defaults/10_disable_services')
            assert (run(service + ' enabled', False).returncode == 0) == enabled
        run('rm /selection.sh; ' + service + ' enable')
        print('PASS saved sysupgrade service state retains enabled and explicitly disabled choices', flush=True)
        inventory = work / 'inventory.yml'
        inventory.write_text('openwrt:\n  hosts:\n    fixture:\n      ansible_connection: community.docker.docker\n      ansible_host: '+name+'\n      openwrt_prometheus_enabled: true\n      openwrt_prometheus_wifi: false\n      openwrt_prometheus_listen_interface: lan\n      openwrt_prometheus_monitor_address: 172.29.244.3\n')
        env = dict(os.environ, ANSIBLE_LOCAL_TEMP=folder)
        cmd = [str(repo/'.venv/bin/ansible-playbook'), '-i', str(inventory), 'playbook.yml', '-t', 'prometheus']

        def play(label, extra=(), success=True):
            result = subprocess.run(cmd+list(extra), cwd=repo, env=env, text=True, capture_output=True)
            if (result.returncode == 0) != success:
                raise AssertionError(label + '\n' + result.stdout[-7000:] + result.stderr)
            return result.stdout

        # Previously reserved pilot paths now belong to the caller, just like
        # any other include/file. Prove that setup does not inspect/remove them.
        run("printf '# unrelated include\\n' >/etc/prometheus-input.nft; "
            "printf 'unrelated file\\n' >/usr/libexec/prometheus-firewall-guard; "
            "uci set firewall.prometheus_input=include; "
            "uci set firewall.prometheus_input.type=nftables; "
            "uci set firewall.prometheus_input.path=/etc/prometheus-input.nft; "
            "uci set firewall.prometheus_input.position=table-pre; uci commit firewall")
        unrelated = 'sha256sum /etc/prometheus-input.nft /usr/libexec/prometheus-firewall-guard; uci show firewall.prometheus_input'
        untouched = run(unrelated).stdout
        play('configure'); expect_listener(True)
        assert run(unrelated).stdout == untouched
        assert peer('172.29.244.3') == 0 and peer('172.29.244.4') != 0
        config = run('cat /etc/config/prometheus-node-exporter-lua').stdout
        assert config.startswith('# Ansible managed\n') and 'monitor_address' not in config and 'option enabled' not in config
        assert run('sha256sum ' + service).stdout == stock
        print('PASS native setup preserves unrelated include/files and stock service; allowed/blocked HTTP verified', flush=True)
        files = 'sha256sum /etc/config/firewall /etc/config/prometheus-node-exporter-lua /etc/apk/world'
        before = run(files).stdout
        play('repeat'); expect_listener(True)
        assert run(files).stdout == before
        assert 'changed=0' in play('check', ['--check'])
        assert run(files).stdout == before
        print('PASS repeated setup preserves config/packages; check mode changes nothing', flush=True)
        docker('restart', name); wait_ready(); expect_listener(True)
        assert peer('172.29.244.3') == 0 and peer('172.29.244.4') != 0
        print('PASS enabled stock service and normal firewall survive ordinary reboot', flush=True)
        # Preflight failure must preserve the currently running service/config.
        run('uci set firewall.prometheus_allow.name=Foreign-Rule; uci commit firewall')
        before = run(files).stdout
        play('foreign', success=False)
        assert run(files).stdout == before and listening()
        run('uci set firewall.prometheus_allow.name=Allow-Prometheus-Zabbix; uci commit firewall')
        print('PASS foreign native rule preserved before any service/package mutation', flush=True)
        for package, edit in [('firewall', 'uci set firewall.prometheus_deny.enabled=0'),
                              ('prometheus-node-exporter-lua', 'uci set prometheus-node-exporter-lua.main.listen_port=9191')]:
            run(edit)
            before = run(files).stdout
            staged = run('uci changes ' + package).stdout
            play('pending-' + package, success=False)
            assert run(files).stdout == before and listening()
            assert run('uci changes ' + package).stdout == staged
            run('uci revert ' + package)
        print('PASS pending firewall/exporter edits preserved before mutation', flush=True)
        # Includes can precede reordered UCI rules, including via fw4's early jump.
        for chain, error in [('input', 'unexpected input rule'),
                             ('syn_flood', 'Unexpected rule in the early syn_flood chain')]:
            payload = 'tcp dport 9100 accept' if chain == 'input' else 'chain syn_flood { tcp dport 9100 accept; }'
            position = 'chain-prepend' if chain == 'input' else 'table-pre'
            run("printf '%s\\n' '" + payload + "' >/etc/test-early.nft; "
                "uci set firewall.test_early=include; uci set firewall.test_early.type=nftables; "
                "uci set firewall.test_early.path=/etc/test-early.nft; "
                "uci set firewall.test_early.position=" + position + "; " +
                ("uci set firewall.test_early.chain=input; " if chain == 'input' else '') +
                "uci commit firewall")
            evidence = 'sha256sum /etc/test-early.nft; uci show firewall.test_early'
            original = run(evidence).stdout
            output = play('early-accept-' + chain, success=False)
            assert error in output, output[-4000:]
            assert any(line.strip() == 'tcp dport 9100 accept'
                       for line in run('nft list chain inet fw4 ' + chain).stdout.splitlines())
            expect_listener(False)
            assert run(service + ' enabled', False).returncode != 0
            assert run(evidence).stdout == original
            assert peer('172.29.244.4') != 0
            run('uci delete firewall.test_early; uci commit firewall; rm /etc/test-early.nft')
            play('retry-early-' + chain); expect_listener(True)
            assert peer('172.29.244.3') == 0 and peer('172.29.244.4') != 0
            print('PASS earlier accept in ' + chain + ' rejected without editing include; retry restores restricted HTTP', flush=True)
        # Force an actual reload failure, after the role has stopped the service.
        run('mv /sbin/fw4 /sbin/fw4.real; printf \'#!/bin/sh\\n[ "$1" != reload ] || exit 42\\nexec /sbin/fw4.real "$@"\\n\' >/sbin/fw4; chmod +x /sbin/fw4')
        play('failed-reload', success=False); expect_listener(False)
        assert run(service + ' enabled', False).returncode != 0
        run('mv /sbin/fw4.real /sbin/fw4')
        play('retry-reload'); expect_listener(True)
        assert peer('172.29.244.3') == 0 and peer('172.29.244.4') != 0
        print('PASS reload failure leaves service disabled; retry recovers restricted listener', flush=True)
        # Simulate interruption after old live rules disappeared, before reload.
        run(service + ' stop; ' + service + ' disable; nft flush chain inet fw4 input')
        play('interrupted-reload'); expect_listener(True)
        assert peer('172.29.244.3') == 0 and peer('172.29.244.4') != 0
        print('PASS interrupted reload and stale live rules repaired on retry', flush=True)
        # Invalid nft content must not start or enable the exporter.
        run("printf 'not valid nft syntax\\n' >/etc/test-invalid.nft; uci set firewall.test_invalid=include; "
            "uci set firewall.test_invalid.type=nftables; uci set firewall.test_invalid.path=/etc/test-invalid.nft; "
            "uci set firewall.test_invalid.position=table-pre; uci commit firewall")
        play('invalid-firewall', success=False); expect_listener(False)
        assert run(service + ' enabled', False).returncode != 0
        run('uci delete firewall.test_invalid; uci commit firewall; rm /etc/test-invalid.nft')
        play('retry-invalid'); expect_listener(True)
        print('PASS invalid firewall prevents provisioning; repair and retry succeed', flush=True)
        assert run('sha256sum ' + service).stdout == stock
        assert run(unrelated).stdout == untouched
        print('All local native exporter checks passed.', flush=True)
    finally:
        docker('rm', '-f', name, check=False)
        docker('network', 'rm', network, check=False)
