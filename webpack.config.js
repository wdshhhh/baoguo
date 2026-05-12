const path    = require("path")
const webpack = require("webpack")
const { VueLoaderPlugin } = require('vue-loader')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
  mode: "production",
  devtool: "source-map",
  target: ["web", "es5"],
  experiments: {
    outputModule: false
  },
  entry: {
    application: "./app/javascript/application.js",
    rails_admin: "./app/javascript/rails_admin.js",
    app: "./app/javascript/packs/app.js",
    app_simple: "./app/javascript/packs/app_simple.js",
    app_test: "./app/javascript/packs/app_test.js",
    app_basic: "./app/javascript/packs/app_basic.js",
    app_simple_login: "./app/javascript/packs/app_simple_login.js",
    app_debug: "./app/javascript/packs/app_debug.js",
    app_main: "./app/javascript/packs/app_main.js"
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    path: path.resolve(__dirname, "public/assets"),
    module: false,
    chunkFormat: "array-push"
  },
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader'
      },
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader']
      },
      {
        test: /\.(png|svg|jpg|jpeg|gif)$/i,
        type: 'asset/resource'
      }
    ]
  },
  plugins: [
    new VueLoaderPlugin(),
    new MiniCssExtractPlugin({
      filename: '[name].css'
    }),
    new webpack.DefinePlugin({
      __VUE_OPTIONS_API__: true,
      __VUE_PROD_DEVTOOLS__: false
    })
  ],
  optimization: {
    runtimeChunk: false,
    splitChunks: false
  }
}
