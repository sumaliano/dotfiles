#!/bin/bash

[[ -f index.html ]] && /usr/bin/rm index.html

cat << _EOF_ > index.html
<style>
 #preview-box {
     background-color: rgba(1,1,1,0.1);
     padding: 1px 10px;
     border-radius: 10px;
 }
</style>
     <style type="text/css">
      div.sourceCode { overflow-x: auto; }
table.sourceCode, tr.sourceCode, td.lineNumbers, td.sourceCode {
  margin: 0; padding: 0; vertical-align: baseline; border: none; }
table.sourceCode { width: 100%; line-height: 100%; }
td.lineNumbers { text-align: right; padding-right: 4px; padding-left: 4px; color: #aaaaaa; border-right: 1px solid #aaaaaa; }
td.sourceCode { padding-left: 5px; }
code > span.kw { color: #007020; font-weight: bold; } /* Keyword */
code > span.dt { color: #902000; } /* DataType */
code > span.dv { color: #40a070; } /* DecVal */
code > span.bn { color: #40a070; } /* BaseN */
code > span.fl { color: #40a070; } /* Float */
code > span.ch { color: #4070a0; } /* Char */
code > span.st { color: #4070a0; } /* String */
code > span.co { color: #60a0b0; font-style: italic; } /* Comment */
code > span.ot { color: #007020; } /* Other */
code > span.al { color: #ff0000; font-weight: bold; } /* Alert */
code > span.fu { color: #06287e; } /* Function */
code > span.er { color: #ff0000; font-weight: bold; } /* Error */
code > span.wa { color: #60a0b0; font-weight: bold; font-style: italic; } /* Warning */
code > span.cn { color: #880000; } /* Constant */
code > span.sc { color: #4070a0; } /* SpecialChar */
code > span.vs { color: #4070a0; } /* VerbatimString */
code > span.ss { color: #bb6688; } /* SpecialString */
code > span.im { } /* Import */
code > span.va { color: #19177c; } /* Variable */
code > span.cf { color: #007020; font-weight: bold; } /* ControlFlow */
code > span.op { color: #666666; } /* Operator */
code > span.bu { } /* BuiltIn */
code > span.ex { } /* Extension */
code > span.pp { color: #bc7a00; } /* Preprocessor */
code > span.at { color: #7d9029; } /* Attribute */
code > span.do { color: #ba2121; font-style: italic; } /* Documentation */
code > span.an { color: #60a0b0; font-weight: bold; font-style: italic; } /* Annotation */
code > span.cv { color: #60a0b0; font-weight: bold; font-style: italic; } /* CommentVar */
code > span.in { color: #60a0b0; font-weight: bold; font-style: italic; } /* Information */
     </style>
<link id="linkstyle" rel='stylesheet' href='markdown.css'/>
<div id="preview-box">
    <strong>Preview another...</strong>
    <select style="width:100%" id="themes">
_EOF_
for f in *.css;
do
	echo "<option value=\"${f}\">${f%.css}</option>" >> index.html;
done
cat << _EOF_ >> index.html
    </select>
</div>
<script>
 var linkstyle = document.getElementById('linkstyle');
 var themes = document.getElementById('themes');

 themes.onchange = function(e) {
     linkstyle.href = themes.value;
 };
</script>

<h1>Markdown css themes</h1>

<hr />

<h1>A First Level Header</h1>

<h2>A Second Level Header</h2>

<h3>A Third Level Header</h3>

<h4>A Fourth Level Header</h4>

<h5>A Fifth Level Header</h5>

<h6>A Sixed Level Header</h6>

<p>Now is the time for all good men to come to
    the aid of their country. This is just a
    regular paragraph.</p>

<p>The quick brown fox jumped over the lazy
    dog&rsquo;s back.</p>

<hr />

<h3>Header 3</h3>

<blockquote><p>This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,
    consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.
    Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.</p>

    <p>Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse
        id sem consectetuer libero luctus adipiscing.</p>

    <h2>This is an H2 in a blockquote</h2>

    <p>This is the first level of quoting.</p>

    <blockquote><p>This is nested blockquote.</p></blockquote>

    <p>Back to the first level.</p></blockquote>

<p>Some of these words <em>are emphasized</em>.
    Some of these words <em>are emphasized also</em>.</p>

<p>Use two asterisks for <strong>strong emphasis</strong>.
    Or, if you prefer, <strong>use two underscores instead</strong>.</p>

<ul>
    <li>Candy.</li>
    <li>Gum.</li>
    <li>Booze.</li>
    <li>Red</li>
    <li>Green</li>
    <li><p>Blue</p></li>
    <li><p>A list item.</p></li>
</ul>


  <div class="sourceCode">
   <pre class="sourceCode sh"><code class="sourceCode bash"><span class="co"># /etc/fstab: static file system information.</span>
<span class="co">#</span>
<span class="co"># Use 'blkid -o value -s UUID' to print the universally unique identifier</span>
<span class="co"># for a device; this may be used with UUID= as a more robust way to name</span>
<span class="co"># devices that works even if disks are added and removed. See fstab(5).</span>
<span class="co">#</span>
<span class="co"># &lt;file system&gt; &lt;mount point&gt;   &lt;type&gt;  &lt;options&gt;       &lt;dump&gt;  &lt;pass&gt;</span>
<span class="ex">proc</span>            /proc           proc    nodev,noexec,nosuid 0       0
<span class="co"># / was on /dev/md3 during installation</span>
<span class="va">UUID=</span>07ff3477-49eb-4ea2-aafc-c24e36483f3b <span class="ex">/</span>               ext4    errors=remount-ro 0       1
<span class="co"># /boot was on /dev/md0 during installation</span>
<span class="va">UUID=</span>8497c10a-8aac-4487-9fe9-9a08643a1f25 <span class="ex">/boot</span>           ext2    defaults        0       2
<span class="co"># /data was on /dev/md4 during installation</span>
<span class="va">UUID=</span>1d651234-09a9-42f3-b56f-763a347656db <span class="ex">/data</span>           ext4    defaults,noatime,nodiratime        0       2
<span class="co"># /home was on /dev/md1 during installation</span>
<span class="va">UUID=</span>e048d8e4-24d8-4ad3-8425-b4ab44130c70 <span class="ex">/home</span>           ext4    defaults        0       2
<span class="co"># /var was on /dev/md2 during installation</span>
<span class="va">UUID=</span>ddee357b-ecd7-4729-8ca6-4590a6393751 <span class="ex">/var</span>            ext4    defaults,noatime,nodiratime        0       2
<span class="co"># swap was on /dev/md5 during installation</span>
<span class="va">UUID=</span>f12863b0-88a5-4639-a575-fbcaa54b34c9 <span class="ex">none</span>            swap    sw              0       0

<span class="co"># /data2 is on /dev/md6</span>
<span class="va">UUID=</span>200bcbd9-4cbd-4b22-81dc-4db335179411 <span class="ex">/data2</span>    ext4    defaults,noatime,nodiratime,data=writeback,errors=remount-ro

<span class="co"># Data directory remote mount from lx-pool.gsi.de</span>
<span class="ex">sshfs</span>#land@lx-pool.gsi.de:/d  /d fuse allow_other,_netdev,noauto,user,noatime 0 0
<span class="co"># Lustre file system mount from lxg0899.gsi.de</span>
<span class="ex">sshfs</span>#land@lxg0897.gsi.de:/lustre /lustre.sshfs fuse allow_other,_netdev,noauto,user,noatime  0 0
<span class="co"># Hera file system mount from lxldatamover02 (via ssh)</span>
<span class="ex">sshfs</span>#land@lxldatamover02.gsi.de:/hera /hera fuse idmap=user,allow_other,_netdev,noauto,user,gid=1119,noatime  0 0
<span class="co"># Lustre file system mount via NFS</span>
<span class="ex">lxnfsl01.gsi.de</span>:/lustre /lustre nfs soft,intr,user 0 0
<span class="co"># Haakan's home mount from lx-pool.gsi.de as land</span>
<span class="ex">sshfs</span>#land@lx-pool.gsi.de:/u/johansso /u.johansso fuse allow_other,_netdev,noauto,user,noatime  0 0
<span class="co"># Land home mount from lx-pool.gsi.de as land</span>
<span class="ex">sshfs</span>#land@lx-pool.gsi.de:/u/land /u.land fuse allow_other,_netdev,noauto,user,noatime  0 0

<span class="co"># /data.esata on external drive</span>
<span class="va">UUID=</span><span class="st">"3E04-830D"</span> <span class="ex">/data.esata</span> vfat defaults,exec,noatime,user,noauto 0 0

<span class="co"># /data.simulation on external drive</span>
<span class="va">UUID=</span><span class="st">"5531955F65B0D556"</span> <span class="ex">/data.simulation</span> ntfs defaults,user,permissions,exec,noatime,noauto 0 0

<span class="co"># /data.usb on external drive</span>
<span class="va">UUID=</span><span class="st">"1C6D-58FC"</span> <span class="ex">/data.usb</span> vfat defaults,exec,noatime,user,noauto 0 0

<span class="co"># /data.munich110707 on external drive</span>
<span class="va">UUID=</span><span class="st">"1F5D56F1436AD0FE"</span> <span class="ex">/data.munich110707</span> ntfs defaults,exec,noatime,user,noauto 0 0

<span class="va">UUID=</span><span class="st">"1C6D-58FC"</span>  <span class="ex">/data.ikp2011</span> vfat  defaults,exec,noatime,user,noauto,ro  0 0
<span class="va">UUID=</span><span class="st">"B3D5-7A14"</span> <span class="ex">/data.duke2012</span> vfat defaults,exec,noatime,user,noauto,ro 0 0
<span class="va">UUID=</span><span class="st">"32D7-6501"</span> <span class="ex">/data.duke2012_2</span> vfat defaults,exec,noatime,user,noauto,ro 0 0
<span class="va">UUID=</span><span class="st">"3860205260201960"</span> <span class="ex">/data.duke2013</span> ntfs defauts,exec,noatime,user,noauto,ro  0 0
<span class="va">UUID=</span><span class="st">"145a032d-9108-4f46-ac24-4d2f36578682"</span> <span class="ex">/data.duke2013_2</span> ext3 defaults,exec,noatime,user,noauto,ro 0 0</code></pre>
  </div>

<p>With multiple paragraphs.</p>

<ul>
    <li><p>Another item in the list.</p></li>
    <li><p>This is a list item with two paragraphs. Lorem ipsum dolor
        sit amet, consectetuer adipiscing elit. Aliquam hendrerit
        mi posuere lectus.</p></li>
</ul>


<p>Vestibulum enim wisi, viverra nec, fringilla in, laoreet
    vitae, risus. Donec sit amet nisl. Aliquam semper ipsum
    sit amet velit.*   Suspendisse id sem consectetuer libero luctus adipiscing.</p>

<ul>
    <li>This is a list item with two paragraphs.</li>
</ul>


<p>This is the second paragraph in the list item. You&rsquo;re
    only required to indent the first line. Lorem ipsum dolor
    sit amet, consectetuer adipiscing elit.</p>

<ul>
    <li><p>Another item in the same list.</p></li>
    <li><p>A list item with a bit of <code>code</code> inline.</p></li>
    <li><p>A list item with a blockquote:</p>

        <blockquote><p>This is a blockquote
            inside a list item.</p></blockquote></li>
</ul>


<p>Here is an example of a pre code block</p>

<pre><code>tell application "Foo"
beep
end tell
</code></pre>

<p>This is an <a href="http://example.com/">example link</a>.</p>

<p>I get 10 times more traffic from <a href="http://google.com/" title="Google">Google</a> than from
    <a href="http://search.yahoo.com/" title="Yahoo Search">Yahoo</a> or <a href="http://search.msn.com/" title="MSN Search">MSN</a>.</p>

<p>I start my morning with a cup of coffee and
    <a href="http://www.nytimes.com/">The New York Times</a>.</p>
_EOF_
