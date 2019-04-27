<!DOCTYPE html>
<html lang="en-US">
<head>
	<meta charset="UTF-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<link rel="icon" type="image/x-icon" href="favicon.ico" />

	<meta name="author" content="João Pinheiro" />
	<meta name="description" content="" />
	<meta name="keywords" content="" />
	<meta property="og:title" content="João Pinheiro" />
	<meta property="og:type" content="profile" />
	<meta property="profile:first_name" content="João" />
	<meta property="profile:last_name" content="Pinheiro" />
	<meta property="profile:username" content="pineman" />
	<meta property="profile:gender" content="male" />
	<meta property="og:image" content="https://www.pineman.win/assets/me.png" />
	<meta property="og:url" content="https://www.pineman.win" />
	<meta property="og:description" content="Personal homepage of João Pinheiro" />
	<meta property="og:site_name" content="pineman.win" />
	<meta property="og:locale" content="en_US" />
	<title>João Pinheiro</title>

	<link rel="stylesheet" href="style.css" />
	<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.1/css/all.css" integrity="sha384-50oBUHEmvpQ+1lW4y57PTFmhCaXp0ML5d60M1M7uH2+nqUivzIebhndOJK28anvf" crossorigin="anonymous">
</head>
<body>
<div id="wrap">
	<header>
	<img src="assets/me.png" />
	<div id ="header-text">
	<h1>Hi! I'm João.</h1>
	<span>Software • Systems • Curiosity</span>
	<ul>
	<li><i class="fa fa-envelope"></i><a href="mailto:joaocastropinheiro@gmail.com">joaocastropinheiro<wbr>@gmail.com</a></li>
	<li><i class="fab fa-github"></i><a href="https://github.com/pineman" target="_blank">GitHub</a></li>
	<li><i class="fab fa-linkedin"></i><a href="https://www.linkedin.com/in/joaocastropinheiro" target="_blank">LinkedIn</a></li>
	<li><i class="fas fa-file-alt" style="padding-left:1px;"></i>CV: <a href="cv/cv.pdf" target="_blank">PDF</a> or <a href="cv" target="_blank">HTML</a></li>
	<li><i class="fab fa-keybase"></i><a href="https://keybase.io/pineman" target="_blank">Keybase</a></li>
	<li><i class="fas fa-key"></i><a href="pubkey.asc" target="_blank">PGP key</a></li>
	<!--<li><i class="fas fa-comments" style="font-size:0.9rem;padding:0 5px 0 -2px;"></i><code>pineman</code> on FreeNode and MozNet-->
	</ul>
	</div>
	</header>
	<article>
	<h1>About me</h1>
	<p>My name is João Pinheiro (aka pineman) and I'm from Lisbon, Portugal. I'm a 4th year Electrical and Computer Engineering student at <a href="https://tecnico.ulisboa.pt/" target="_blank">Técnico Lisboa</a>. I'm passionate about distributed, fault tolerant, concurrent systems and software infrastructure overall.</p>

	<p>Currently I'm experienced in <b>C</b>, <b>Python</b>, <b>JavaScript</b> (& <b>Node.js</b>), and <b>C++/Qt</b>. I'm most comfortable on <b>GNU/Linux</b> but I love Operating Systems generally, as I'm always very keen on learning new technologies and solutions. When I can, I dabble with Functional Programming and I'm very interested in Rust and Erlang/Elixir.</p>

	<p>This server is running <a href="https://www.archlinux.org/" target="_blank">Arch Linux</a> (<?php echo trim(shell_exec('uptime -p'));?>) and I manage it since 2014 as a learning platform. It runs various services like <b>HTTP</b> (nginx), <b>Git</b>, <b>SMB</b>, <b>SMTP</b> (postfix), <b>IMAP</b> (dovecot), ZNC and Radicale (all config files available <a href="https://github.com/pineman/pinecone" target="_blank">here</a>). It also hosts some friend's webpages, and some projects, like <a href="https://abra.pineman.win" target="_blank">abra</a>, a keyboard typing speed browser game.</p>
	</article>
</div>
</body>
</html>
