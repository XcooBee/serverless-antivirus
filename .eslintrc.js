module.exports = {
    env: {
        browser: false,
        commonjs: true,
        es6: true,
        node: true,
    },
    extends: "airbnb-base",
    parserOptions: {
        ecmaVersion: 2018
    },
    rules: {
        indent: ["error", 4],
        "no-underscore-dangle": "off",
    },
};