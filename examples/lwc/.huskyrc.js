module.exports = {
    hooks: {
        'pre-commit':
            'pretty-quick --staged --no-restage --pattern "src/main/modules/**/*.{css,html,js}"'
    }
};
