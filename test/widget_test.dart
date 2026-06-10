import 'package:flutter_test/flutter_test.dart';
import 'package:law_buddy/services/database_service.dart';

void main() {
  test('DatabaseService initialization sanity check', () {
    final dbService = DatabaseService();
    expect(dbService, isNotNull);
  });
}
