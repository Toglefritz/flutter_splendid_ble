/// Extension to add a 'capitalize' method to [String].
///
/// This extension provides a method to capitalize the first letter of a given string while making all other letters
/// lowercase.
extension StringCapitalization on String {
  /// Returns a new string where the first letter is capitalized and the remaining letters are converted to lowercase.
  ///
  /// If the string is empty, it returns an empty string.
  ///
  /// ## Examples
  /// ```dart
  /// print('hello'.capitalize()); // Output: Hello
  /// print('WORLD'.capitalize()); // Output: World
  /// print(''.capitalize());     // Output: (empty string)
  /// ```
  String capitalize() {
    if (isEmpty) {
      return '';
    }
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
