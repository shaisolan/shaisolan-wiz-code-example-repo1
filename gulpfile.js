// gulpfile.js

const gulp        = require('gulp');
const concat      = require('gulp-concat');
const uglify      = require('gulp-uglify');
const cleanCSS    = require('gulp-clean-css');
const htmlreplace = require('gulp-html-replace');
const { exec }    = require('child_process');
const imagemin    = require('gulp-imagemin');
const { deleteAsync } = require('del');    // <-- note deleteAsync

// Define paths
const paths = {
  styles: { src: 'public/css/**/*.css', dest: 'dist/public/css/' },
  scripts: { src: 'public/js/**/*.js', dest: 'dist/public/js/' },
  other: { src: ['app.js', 'package.json', 'package-lock.json'], dest: 'dist/' },
  views: { src: 'views/**/*.mustache', dest: 'dist/views/' },
  data: { src: 'data/**/*', dest: 'dist/data/' },
  images: { src: 'public/images/**/*', dest: 'dist/public/images/' },
  dockerfile: { src: 'Dockerfile', dest: 'dist/' }
};

// 1) Clean
function clean() {
  return deleteAsync(['dist']);
}

// 2) Styles
function styles() {
  return gulp.src(paths.styles.src)
    .pipe(concat('main.min.css'))
    .pipe(cleanCSS())
    .pipe(gulp.dest(paths.styles.dest));
}

// 3) Scripts
function scripts() {
  return gulp.src(paths.scripts.src)
    .pipe(concat('main.min.js'))
    .pipe(uglify())
    .pipe(gulp.dest(paths.scripts.dest));
}

// 4) HTML replace
function replaceUrls() {
  return gulp.src(paths.views.src)
    .pipe(htmlreplace({ css: '/css/main.min.css', js: '/js/main.min.js' }))
    .pipe(gulp.dest(paths.views.dest));
}

// 5) Copy other assets
function copyOther()     { return gulp.src(paths.other.src).pipe(gulp.dest(paths.other.dest)); }
function copyViews()     { return gulp.src(paths.views.src).pipe(gulp.dest(paths.views.dest)); }
function copyData()      { return gulp.src(paths.data.src).pipe(gulp.dest(paths.data.dest)); }
function copyDockerfile(){ return gulp.src(paths.dockerfile.src).pipe(gulp.dest(paths.dockerfile.dest)); }

// 6) Images (minimize safely)
function copyImages() {
  return gulp.src(paths.images.src, { encoding: false })
    .pipe(imagemin())
    .pipe(gulp.dest(paths.images.dest))
    .on('error', err => console.error('Error in copyImages task', err.toString()));
}

// 7) npm install in dist
function npmInstall(cb) {
  exec('npm install', { cwd: 'dist' }, (err, stdout, stderr) => {
    if (err) return cb(err);
    console.log(stdout, stderr);
    cb();
  });
}

// Composite tasks
const build = gulp.series(
  clean,
  gulp.parallel(styles, scripts, replaceUrls, copyOther, copyViews, copyData, copyImages, copyDockerfile),
  npmInstall
);

// Expose tasks
module.exports = {
  clean,
  styles,
  scripts,
  replaceUrls,
  copyOther,
  copyViews,
  copyData,
  copyImages,
  copyDockerfile,
  npmInstall,
  build,
  default: build
};
