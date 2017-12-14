// Include gulp
var gulp = require('gulp');

// Include Our Plugins
var concat = require('gulp-concat');
var uglify = require('gulp-uglify');
var rename = require('gulp-rename');

function swallowError (error) {
    // If you want details of the error in the console
    console.log(error.toString())
    this.emit('end');
}

// Concatenate & Minify JS
gulp.task('module_scripts', function() {
    return gulp.src(['finish/*.js'])
        .pipe(concat('all.js'))
		.on('error', swallowError)
        .pipe(gulp.dest('dist'))
        .pipe(rename({ suffix: '.min' }))
		.pipe(uglify())
		.on('error', swallowError)
        .pipe(gulp.dest('dist/js'));
});

// Default Task
gulp.task('default', ['module_scripts']);