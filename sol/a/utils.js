const fs = require('fs');
const repl = require('repl');
const git = require('simple-git')('.');

module.exports = {
    test: function () { repl.repl.eval("test", null, null, async (x) => {}) },
    watch: function () {
        git.raw(['ls-files'], (err, result) => {
            let fns = result.trim().split('\n')
            for (let fn of fns) {
                fs.watchFile(fn, async (prev, curr) => {
                    console.log(`file changed: ${fn}`);
                    this.test();
                })
            }
        })
    },
};
