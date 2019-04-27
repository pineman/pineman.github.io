'use strict';

const gulp = require('gulp');
const spawn = require('child_process').spawn;
const path = require('path');
const rm = require('fs').unlinkSync;

const OUT_DIR = '.';

const LESS_DIR = '.';
const LESS_IN = `${LESS_DIR}/style.less`;
const LESS_WATCH = `${LESS_DIR}/**/*.less`;
const LESS_OUT = `${OUT_DIR}/style.css`;

function run(command) {
	command = command.split(' ');
	const proc = spawn(command[0], command.slice(1), {
		stdio: 'inherit',
		shell: true
	});
	proc.on('close', (code) => {
		if (code) process.exit(code);
	});
}

gulp.task('clean', (done) => {
	try {
		rm(LESS_OUT);
	} catch (err) { };
	done();
});

gulp.task('watch', () => {
	gulp.watch(LESS_WATCH, gulp.parallel('less'));
});

gulp.task('less', (done) => {
	const opt = [
		'--verbose',
		'--source-map-map-inline',
		'--clean-css',
		'--autoprefix="> 0.2%"'
	].join(' ');

	run(`lessc ${opt} ${LESS_IN} ${LESS_OUT}`);
	done();
});

gulp.task('default', gulp.parallel(['less']));
