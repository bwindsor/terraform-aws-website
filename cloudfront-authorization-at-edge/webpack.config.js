const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
  mode: 'production',
  target: 'node',
  node: {
    __dirname: false
  },
  entry: {
    'dist/parse-auth': path.resolve(__dirname, './src/parse_auth.ts'),
    'dist/check-auth': path.resolve(__dirname, './src/check_auth.ts'),
    'dist/refresh-auth': path.resolve(__dirname, './src/refresh_auth.ts'),
    'dist/http-headers': path.resolve(__dirname, './src/http_headers.ts'),
    'dist/sign-out': path.resolve(__dirname, './src/sign_out.ts'),
    'dist/redirects': path.resolve(__dirname, './src/redirects.ts'),
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: 'ts-loader',
        exclude: /node_modules/
      },
      {
        test: /\.html$/i,
        loader: 'html-loader',
        options: {
          minimize: true,
        },
      },
    ]
  },
  resolve: {
    extensions: [ '.ts', '.js' ]
  },
  output: {
    path: path.resolve(__dirname),
    filename: '[name].js',
    libraryTarget: 'commonjs',
  },
  externals: [
    /^aws-sdk/ // Don't include the aws-sdk in bundles as it is already present in the Lambda runtime
  ],
  performance: {
    hints: 'error',
    maxAssetSize: 1048576, // Max size of deployment bundle in Lambda@Edge Viewer Request
    maxEntrypointSize: 1048576, // Max size of deployment bundle in Lambda@Edge Viewer Request
  },
  optimization: {
    minimizer: [new TerserPlugin({
      cache: true,
      parallel: true,
      extractComments: false,
    })],
  },
}
