<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: var(--font-mono); }
.wrap { max-width: 860px; padding: 2rem 1.5rem; }
.badge { display: inline-block; font-size: 11px; font-weight: 500; padding: 3px 10px; border-radius: 20px; margin-right: 6px; margin-bottom: 6px; font-family: var(--font-sans); }
.badge-green { background: #EAF3DE; color: #3B6D11; }
.badge-blue { background: #E6F1FB; color: #185FA5; }
.badge-gray { background: #F1EFE8; color: #5F5E5A; }
.badge-amber { background: #FAEEDA; color: #854F0B; }
h1 { font-size: 22px; font-weight: 500; color: var(--color-text-primary); font-family: var(--font-sans); margin-bottom: 4px; }
h2 { font-size: 15px; font-weight: 500; color: var(--color-text-primary); font-family: var(--font-sans); margin: 2rem 0 0.75rem; padding-bottom: 6px; border-bottom: 0.5px solid var(--color-border-tertiary); }
h3 { font-size: 13px; font-weight: 500; color: var(--color-text-secondary); font-family: var(--font-sans); margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.05em; }
p { font-size: 14px; color: var(--color-text-secondary); line-height: 1.7; font-family: var(--font-sans); }
code { font-family: var(--font-mono); font-size: 12px; background: var(--color-background-secondary); padding: 1px 5px; border-radius: 4px; color: var(--color-text-primary); }
pre { background: var(--color-background-secondary); border: 0.5px solid var(--color-border-tertiary); border-radius: var(--border-radius-md); padding: 1rem; font-size: 12px; line-height: 1.7; overflow-x: auto; color: var(--color-text-primary); margin: 0.75rem 0; }
.divider { border: none; border-top: 0.5px solid var(--color-border-tertiary); margin: 0.5rem 0 1rem; }
.meta { font-size: 13px; color: var(--color-text-secondary); font-family: var(--font-sans); margin-bottom: 1.25rem; }
.meta span { margin-right: 1.5rem; }
.finding { background: var(--color-background-secondary); border-left: 3px solid #378ADD; border-radius: 0 var(--border-radius-md) var(--border-radius-md) 0; padding: 10px 14px; margin: 8px 0; }
.finding p { font-size: 13px; margin: 0; }
.finding strong { color: var(--color-text-primary); font-weight: 500; }
.flow { display: flex; align-items: center; gap: 0; margin: 1rem 0; flex-wrap: wrap; gap: 6px; }
.fbox { background: var(--color-background-primary); border: 0.5px solid var(--color-border-tertiary); border-radius: var(--border-radius-md); padding: 8px 14px; font-size: 13px; font-family: var(--font-mono); color: var(--color-text-primary); white-space: nowrap; }
.fbox.accent { background: #E6F1FB; color: #185FA5; border-color: #B5D4F4; }
.farrow { color: var(--color-text-secondary); font-size: 16px; padding: 0 2px; }
table { width: 100%; border-collapse: collapse; font-size: 13px; font-family: var(--font-sans); }
th { text-align: left; padding: 8px 12px; color: var(--color-text-secondary); font-weight: 500; border-bottom: 0.5px solid var(--color-border-tertiary); font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; }
td { padding: 8px 12px; color: var(--color-text-primary); border-bottom: 0.5px solid var(--color-border-tertiary); vertical-align: top; }
td code { font-size: 11px; }
tr:last-child td { border-bottom: none; }
.tbl-wrap { border: 0.5px solid var(--color-border-tertiary); border-radius: var(--border-radius-md); overflow: hidden; margin: 0.75rem 0; }
.status-ok { color: #3B6D11; font-weight: 500; }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 0.75rem 0; }
.card-sm { background: var(--color-background-secondary); border-radius: var(--border-radius-md); padding: 12px 14px; }
.card-sm p { font-size: 12px; margin-top: 4px; }
.card-sm h3 { font-size: 12px; margin-bottom: 2px; }
@media (max-width: 500px) { .grid2 { grid-template-columns: 1fr; } }
</style>

<div class="wrap">

<div style="margin-bottom:1.5rem;">
  <h1>🛡 Self-Healing OS — Alpine Linux</h1>
  <div class="meta" style="margin-top:8px;">
    <span>Nimit Mishra · 1SI24CS116</span>
    <span>SIT Tumkur</span>
    <span>June 2026</span>
  </div>
  <div>
    <span class="badge badge-green">Alpine Linux 3.x</span>
    <span class="badge badge-blue">OpenRC · BusyBox</span>
    <span class="badge badge-gray">POSIX Shell</span>
    <span class="badge badge-amber">Phase 1 — No AI</span>
  </div>
</div>

<p>A lightweight autonomous fault management system for Alpine Linux. Monitors for three categories of OS-level failure every 10 seconds and applies corrective patches automatically — no human intervention required after the initial fault is triggered.</p>

<h2>How it works</h2>
<p style="margin-bottom:10px;">Every failure follows the same three-stage cycle (based on the MAPE loop from autonomic computing research):</p>
<div class="flow">
  <div class="fbox accent">detect_*.sh</div>
  <div class="farrow">→</div>
  <div class="fbox">exit 1?</div>
  <div class="farrow">→</div>
  <div class="fbox accent">patch_*.sh</div>
  <div class="farrow">→</div>
  <div class="fbox accent">detect_*.sh</div>
  <div class="farrow">→</div>
  <div class="fbox">exit 0 ✓</div>
</div>
<p style="margin-top:8px;"><code>monitor.sh</code> runs this loop for all three failures concurrently, every 10 seconds, logging everything to <code>/var/log/monitor.log</code>.</p>

<h2>Three failure types — all proven</h2>
<div class="tbl-wrap">
  <table>
    <thead><tr><th>Failure</th><th>How simulated</th><th>How auto-fixed</th><th>Status</th></tr></thead>
    <tbody>
      <tr>
        <td><code>/tmp</code> full (tmpfs)</td>
        <td><code>dd if=/dev/zero of=/tmp/bigfile bs=1M count=500</code></td>
        <td>Delete junk file, clean files older than 1 day</td>
        <td class="status-ok">✓ Proven</td>
      </tr>
      <tr>
        <td><code>sshd</code> crash (OpenRC)</td>
        <td><code>rc-service sshd stop</code></td>
        <td><code>rc-service sshd start</code></td>
        <td class="status-ok">✓ Proven</td>
      </tr>
      <tr>
        <td>Device removed (<code>/dev/sdb</code>)</td>
        <td><code>echo 1 > /sys/block/sdb/device/delete</code></td>
        <td>SCSI rescan + remount (3 retry limit)</td>
        <td class="status-ok">✓ Proven</td>
      </tr>
    </tbody>
  </table>
</div>
<p>All three were triggered simultaneously and all three healed within a single 10-second monitor cycle.</p>

<h2>Scripts</h2>
<div class="tbl-wrap">
  <table>
    <thead><tr><th>Script</th><th>Location</th><th>Purpose</th></tr></thead>
    <tbody>
      <tr><td><code>detect_disk.sh</code></td><td><code>/usr/local/bin/</code></td><td>Checks <code>/tmp</code> usage &gt; 85%</td></tr>
      <tr><td><code>patch_disk.sh</code></td><td><code>/usr/local/bin/</code></td><td>Cleans <code>/tmp</code> junk files</td></tr>
      <tr><td><code>detect_service.sh</code></td><td><code>/usr/local/bin/</code></td><td>Checks if <code>sshd</code> is running (OpenRC)</td></tr>
      <tr><td><code>patch_service.sh</code></td><td><code>/usr/local/bin/</code></td><td>Restarts <code>sshd</code> via <code>rc-service</code></td></tr>
      <tr><td><code>detect_device.sh</code></td><td><code>/usr/local/bin/</code></td><td>Write-tests <code>/mnt/fakeusb</code></td></tr>
      <tr><td><code>patch_device.sh</code></td><td><code>/usr/local/bin/</code></td><td>SCSI rescan + remount <code>/dev/sdb</code></td></tr>
      <tr><td><code>monitor.sh</code></td><td><code>/usr/local/bin/</code></td><td>Runs all checks every 10 seconds</td></tr>
    </tbody>
  </table>
</div>

<h2>Install &amp; run</h2>
<pre>cp scripts/*.sh /usr/local/bin/
chmod +x /usr/local/bin/*.sh

# One-time device setup
mkfs.ext4 /dev/sdb
mkdir -p /mnt/fakeusb
mount /dev/sdb /mnt/fakeusb

# Start the monitor
/usr/local/bin/monitor.sh > /var/log/monitor.log 2>&1 &

# Watch it live
tail -f /var/log/monitor.log</pre>

<h2>Key research findings</h2>

<div class="finding">
  <p><strong>1. tmpfs vs root disk</strong> — Alpine's <code>/tmp</code> is RAM-backed and fills independently of the root disk. A monitor watching only the root partition misses this failure entirely.</p>
</div>
<div class="finding">
  <p><strong>2. Page cache false negative</strong> — <code>ls /mnt/fakeusb</code> returns cached results from RAM even after the device is removed. The fix: a write test (<code>echo x > .healthcheck</code>), which cannot be served from cache.</p>
</div>
<div class="finding">
  <p><strong>3. OpenRC vs systemd</strong> — All service commands use <code>rc-service</code>, not <code>systemctl</code>. Alpine has no systemd. AI models trained on Ubuntu will generate wrong commands here.</p>
</div>
<div class="finding">
  <p><strong>4. Retry counter storage</strong> — <code>patch_device.sh</code> stores its retry counter in <code>/tmp</code>, which is wiped on reboot. A production system should use <code>/var/lib/</code> for persistent state.</p>
</div>

<h2>Setup</h2>
<p style="margin-bottom:10px;">Tested on Alpine Linux 3.x inside VirtualBox on Windows host.</p>
<div class="grid2">
  <div class="card-sm">
    <h3>OS</h3>
    <p>Alpine Linux · musl libc · BusyBox · OpenRC init</p>
  </div>
  <div class="card-sm">
    <h3>Virtualisation</h3>
    <p>Oracle VirtualBox · NAT port forwarding · SSH on port 2222</p>
  </div>
  <div class="card-sm">
    <h3>Storage</h3>
    <p>100MB VDI second disk (<code>fake_usb.vdi</code>) as <code>/dev/sdb</code></p>
  </div>
  <div class="card-sm">
    <h3>Next phase</h3>
    <p>5-layer safety system + AI-generated patches (Claude API · Ollama)</p>
  </div>
</div>

<hr class="divider" style="margin-top:2rem;">
<p style="font-size:12px; color:var(--color-text-secondary);">Phase 1 — Manual Baseline · Research project, SIT Tumkur · June 2026</p>

</div>
