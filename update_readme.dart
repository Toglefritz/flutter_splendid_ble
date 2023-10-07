import 'dart:io';

/// A Dart script to automatically update the version number in a README.md file based on the version defined in the
/// pubspec.yaml file.
void main() {
  // 1. Read the pubspec.yaml file to extract the current version.
  final pubspec = File('pubspec.yaml');
  final readme = File('README.md');

  // 2. Use a regular expression to find and extract the version number.
  final String? versionLine = RegExp(r'version:\s*(\d+\.\d+\.\d+)').firstMatch(pubspec.readAsStringSync())?.group(1);

  // 3. Read the existing content of the README.md file.
  final String readmeContent = readme.readAsStringSync();

  // 4. Replace the version number in the specified line with the updated version.
  final String updatedReadme = readmeContent.replaceAllMapped(
    RegExp(r'flutter_ble:\s*(\d+\.\d+\.\d+)'),
    (match) => 'flutter_ble: ^$versionLine',
  );

  // 5. Write the updated content back to the README.md file.
  readme.writeAsStringSync(updatedReadme);
}
