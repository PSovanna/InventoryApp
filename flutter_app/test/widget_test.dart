import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:catalog_app/views/add_category.dart';
import 'package:catalog_app/category_service.dart';
import 'package:catalog_app/views/phone_frame.dart';

void main() {
  testWidgets('Empty category name prevents submission', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => PhoneFrame(child: child!),
        home: AddCategoryPage(service: CategoryService()),
      ),
    );
    expect(find.text('No image selected'), findsOneWidget);
    expect(find.text('Choose Image'), findsOneWidget);
    expect(find.byType(PhoneFrame), findsOneWidget);
    expect(tester.getSize(find.byType(Scaffold)).width, lessThan(400));
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a category name'), findsOneWidget);
  });
}
