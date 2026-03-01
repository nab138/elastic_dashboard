import 'package:flutter/material.dart';

import 'package:dot_cast/dot_cast.dart';
import 'package:provider/provider.dart';

import 'package:elastic_dashboard/services/nt4_client.dart';
import 'package:elastic_dashboard/widgets/dialog_widgets/dialog_color_picker.dart';
import 'package:elastic_dashboard/widgets/nt_widgets/nt_widget.dart';

class StatusDisplayModel extends MultiTopicNTWidgetModel {
  @override
  String type = StatusDisplay.widgetType;

  String get booleanTopic => '$topic/Boolean';
  String get shiftNameTopic => '$topic/ShiftName';
  String get shiftLengthTopic => '$topic/ShiftLength';
  String get remainingTimeTopic => '$topic/RemainingTime';

  late NT4Subscription booleanSubscription;
  late NT4Subscription shiftNameSubscription;
  late NT4Subscription shiftLengthSubscription;
  late NT4Subscription remainingTimeSubscription;

  @override
  List<NT4Subscription> get subscriptions => [
    booleanSubscription,
    shiftNameSubscription,
    shiftLengthSubscription,
    remainingTimeSubscription,
  ];

  Color _trueColor = Colors.green;
  Color _falseColor = Colors.red;

  Color get trueColor => _trueColor;

  set trueColor(Color value) {
    _trueColor = value;
    refresh();
  }

  Color get falseColor => _falseColor;

  set falseColor(Color value) {
    _falseColor = value;
    refresh();
  }

  StatusDisplayModel({
    required super.ntConnection,
    required super.preferences,
    required super.topic,
    Color trueColor = Colors.green,
    Color falseColor = Colors.red,
    super.period,
  }) : _trueColor = trueColor,
       _falseColor = falseColor,
       super();

  StatusDisplayModel.fromJson({
    required super.ntConnection,
    required super.preferences,
    required Map<String, dynamic> jsonData,
  }) : super.fromJson(jsonData: jsonData) {
    _trueColor = Color(
      tryCast(jsonData['true_color']) ?? Colors.green.toARGB32(),
    );
    _falseColor = Color(
      tryCast(jsonData['false_color']) ?? Colors.red.toARGB32(),
    );
  }

  @override
  void initializeSubscriptions() {
    booleanSubscription = ntConnection.subscribe(booleanTopic, super.period);
    shiftNameSubscription = ntConnection.subscribe(
      shiftNameTopic,
      super.period,
    );
    shiftLengthSubscription = ntConnection.subscribe(
      shiftLengthTopic,
      super.period,
    );
    remainingTimeSubscription = ntConnection.subscribe(
      remainingTimeTopic,
      super.period,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'true_color': _trueColor.toARGB32(),
    'false_color': _falseColor.toARGB32(),
  };

  @override
  List<Widget> getEditProperties(BuildContext context) => [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: [
        DialogColorPicker(
          onColorPicked: (Color color) {
            trueColor = color;
          },
          label: 'True Color',
          initialColor: _trueColor,
          defaultColor: Colors.green,
        ),
        const SizedBox(width: 10),
        DialogColorPicker(
          onColorPicked: (Color color) {
            falseColor = color;
          },
          label: 'False Color',
          initialColor: _falseColor,
          defaultColor: Colors.red,
        ),
      ],
    ),
  ];
}

class StatusDisplay extends NTWidget {
  static const String widgetType = 'Status Display';

  const StatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    StatusDisplayModel model = cast(context.watch<NTWidgetModel>());

    return ListenableBuilder(
      listenable: Listenable.merge(model.subscriptions),
      builder: (context, child) {
        bool boolValue = tryCast(model.booleanSubscription.value) ?? false;
        String shiftName = tryCast(model.shiftNameSubscription.value) ?? '';
        double shiftLength =
            tryCast<num>(model.shiftLengthSubscription.value)?.toDouble() ??
            1.0;
        double remainingTime =
            tryCast<num>(model.remainingTimeSubscription.value)?.toDouble() ??
            0.0;

        Color backgroundColor = boolValue ? model.trueColor : model.falseColor;

        double progress = shiftLength > 0
            ? (1.0 - remainingTime / shiftLength).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: backgroundColor,
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Remaining time text
              Expanded(
                flex: 5,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    '${remainingTime.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Shift name label
              Expanded(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    shiftName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
