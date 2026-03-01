import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/services/nt4_type.dart';
import 'package:elastic_dashboard/services/nt_connection.dart';
import 'package:elastic_dashboard/services/nt_widget_registry.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_color_picker.dart';
import 'package:elastic_dashboard/widgets/draggable_containers/draggable_nt_widget_container.dart';
import 'package:elastic_dashboard/widgets/draggable_containers/models/nt_widget_container_model.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/multi_topic/status_display.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';
import '../../../test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> statusDisplayJson = {
    'topic': 'Test/Status',
    'period': 0.100,
    'true_color': Colors.green.toARGB32(),
    'false_color': Colors.red.toARGB32(),
  };

  late SharedPreferences preferences;
  late NTConnection ntConnection;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();

    ntConnection = createMockOnlineNT4(
      virtualTopics: [
        NT4Topic(
          name: 'Test/Status/Boolean',
          type: NT4Type.boolean(),
          properties: {},
        ),
        NT4Topic(
          name: 'Test/Status/ShiftName',
          type: NT4Type.string(),
          properties: {},
        ),
        NT4Topic(
          name: 'Test/Status/ShiftLength',
          type: NT4Type.float(),
          properties: {},
        ),
        NT4Topic(
          name: 'Test/Status/RemainingTime',
          type: NT4Type.float(),
          properties: {},
        ),
      ],
      virtualValues: {
        'Test/Status/Boolean': false,
        'Test/Status/ShiftName': 'Morning Shift',
        'Test/Status/ShiftLength': 120.0,
        'Test/Status/RemainingTime': 45.0,
      },
    );
  });

  test('Status display from json', () {
    NTWidgetModel statusDisplayModel = NTWidgetRegistry.buildNTModelFromJson(
      ntConnection,
      preferences,
      'Status Display',
      statusDisplayJson,
    );

    expect(statusDisplayModel.type, 'Status Display');
    expect(statusDisplayModel.runtimeType, StatusDisplayModel);

    if (statusDisplayModel is! StatusDisplayModel) {
      return;
    }

    expect(statusDisplayModel.trueColor, Color(Colors.green.toARGB32()));
    expect(statusDisplayModel.falseColor, Color(Colors.red.toARGB32()));
  });

  test('Status display to json', () {
    StatusDisplayModel statusDisplayModel = StatusDisplayModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/Status',
      trueColor: Colors.green,
      falseColor: Colors.red,
      period: 0.100,
    );

    expect(statusDisplayModel.toJson(), statusDisplayJson);
  });

  testWidgets('Status display shows false color and content', (
    widgetTester,
  ) async {
    FlutterError.onError = ignoreOverflowErrors;

    StatusDisplayModel statusDisplayModel = StatusDisplayModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/Status',
      period: 0.100,
    );

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NTWidgetModel>.value(
            value: statusDisplayModel,
            child: const StatusDisplay(),
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    expect(find.text('Morning Shift'), findsOneWidget);
    expect(find.text('45.0s'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color?.toARGB32() ==
                Colors.red.toARGB32(),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Status display shows true color when boolean is true', (
    widgetTester,
  ) async {
    FlutterError.onError = ignoreOverflowErrors;

    NTConnection trueNTConnection = createMockOnlineNT4(
      virtualTopics: [
        NT4Topic(
          name: 'Test/Status/Boolean',
          type: NT4Type.boolean(),
          properties: {},
        ),
        NT4Topic(
          name: 'Test/Status/ShiftName',
          type: NT4Type.string(),
          properties: {},
        ),
        NT4Topic(
          name: 'Test/Status/ShiftLength',
          type: NT4Type.float(),
          properties: {},
        ),
        NT4Topic(
          name: 'Test/Status/RemainingTime',
          type: NT4Type.float(),
          properties: {},
        ),
      ],
      virtualValues: {
        'Test/Status/Boolean': true,
        'Test/Status/ShiftName': 'All Good',
        'Test/Status/ShiftLength': 100.0,
        'Test/Status/RemainingTime': 75.0,
      },
    );

    StatusDisplayModel statusDisplayModel = StatusDisplayModel(
      ntConnection: trueNTConnection,
      preferences: preferences,
      topic: 'Test/Status',
      period: 0.100,
    );

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NTWidgetModel>.value(
            value: statusDisplayModel,
            child: const StatusDisplay(),
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    expect(find.text('All Good'), findsOneWidget);
    expect(find.text('75.0s'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color?.toARGB32() ==
                Colors.green.toARGB32(),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Status display edit properties', (widgetTester) async {
    FlutterError.onError = ignoreOverflowErrors;

    StatusDisplayModel statusDisplayModel = StatusDisplayModel(
      ntConnection: ntConnection,
      preferences: preferences,
      topic: 'Test/Status',
      period: 0.100,
    );

    NTWidgetContainerModel ntContainerModel = NTWidgetContainerModel(
      ntConnection: ntConnection,
      preferences: preferences,
      initialPosition: Rect.zero,
      title: 'Status Display',
      childModel: statusDisplayModel,
    );

    final key = GlobalKey();

    await widgetTester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NTWidgetContainerModel>.value(
            key: key,
            value: ntContainerModel,
            child: const DraggableNTWidgetContainer(),
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    ntContainerModel.showEditProperties(key.currentContext!);

    await widgetTester.pumpAndSettle();

    expect(
      find.widgetWithText(DialogColorPicker, 'True Color'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(DialogColorPicker, 'False Color'),
      findsOneWidget,
    );
  });
}
