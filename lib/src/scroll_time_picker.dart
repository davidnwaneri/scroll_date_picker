import 'package:flutter/material.dart';
import 'package:scroll_date_picker/src/models/date_picker_scroll_view_options.dart'
    show ScrollViewDetailOptions;
import 'package:scroll_date_picker/src/widgets/date_scroll_view.dart';

import 'models/date_picker_options.dart';

class ScrollTimePicker extends StatefulWidget {
  const ScrollTimePicker({
    required this.selectedTime,
    required this.onTimeChanged,
    this.options = const DatePickerOptions(),
    this.scrollViewOptions = const TimePickerScrollViewOptions(),
    this.locale = const Locale('en'),
    this.viewType,
    this.indicator,
    super.key,
  });

  /// The currently selected time.
  final TimeOfDay selectedTime;

  /// On optional listener that's called when the centered item changes.
  final ValueChanged<TimeOfDay> onTimeChanged;

  /// A set that allows you to specify options related to ListWheelScrollView.
  final DatePickerOptions options;

  /// A set that allows you to specify options related to ScrollView.
  final TimePickerScrollViewOptions scrollViewOptions;

  /// Set calendar language
  final Locale locale;

  /// A list that allows you to specify the type of time view.
  /// And also the order of the viewType in list is the order of the date view.
  /// If this list is null, the default order of locale is set.
  final List<TimePickerViewType>? viewType;

  /// Indicator displayed in the center of the ScrollDatePicker
  final Widget? indicator;

  @override
  State<ScrollTimePicker> createState() => _ScrollTimePickerState();
}

class _ScrollTimePickerState extends State<ScrollTimePicker> {
  /// This widget's hour selection and animation state.
  late FixedExtentScrollController _hourController;

  /// This widget's minute selection and animation state.
  late FixedExtentScrollController _minuteController;

  /// This widget's "time indicators in the 12-hour clock system" selection and animation state.
  late FixedExtentScrollController _dayPeriodController;

  late Widget _hourScrollView;
  late Widget _minuteScrollView;
  late Widget _dayPeriodScrollView;

  late TimeOfDay _selectedTime;
  late final List<int> _hours;
  late final List<int> _minutes;
  late final List<DayPeriod> _dayPeriod;

  int get selectedHourIndex {
    final hour = _selectedTime.period == DayPeriod.am
        ? _selectedTime.hour
        : (_selectedTime.hour - 12);

    return !_hours.contains(hour) ? 0 : _hours.indexOf(hour);
  }

  int get selectedMinuteIndex {
    return !_minutes.contains(_selectedTime.minute)
        ? 0
        : _minutes.indexOf(_selectedTime.minute);
  }

  int get selectedDayPeriodIndex {
    return _dayPeriod.indexOf(_selectedTime.period);
  }

  int get selectedHour {
    if (_hourController.hasClients) {
      return _hours[_hourController.selectedItem % _hours.length];
    }
    return TimeOfDay.now().hour;
  }

  int get selectedMinute {
    if (_minuteController.hasClients) {
      return _minutes[_minuteController.selectedItem % _minutes.length];
    }
    return TimeOfDay.now().minute;
  }

  DayPeriod get selectedDayPeriod {
    if (_dayPeriodController.hasClients) {
      return _dayPeriod[_dayPeriodController.selectedItem % _dayPeriod.length];
    }
    return TimeOfDay.now().period;
  }

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.selectedTime;

    _hours = [
      for (int i = 1; i <= 12; i++) i,
    ];
    _minutes = [
      for (int i = 0; i < 60; i++) i,
    ];
    _dayPeriod = DayPeriod.values;

    _hourController =
        FixedExtentScrollController(initialItem: selectedHourIndex);
    _minuteController =
        FixedExtentScrollController(initialItem: selectedMinuteIndex);
    _dayPeriodController =
        FixedExtentScrollController(initialItem: selectedDayPeriodIndex);
  }

  @override
  void didUpdateWidget(covariant ScrollTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedTime != widget.selectedTime) {
      _selectedTime = widget.selectedTime;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hourController.animateToItem(selectedHourIndex,
            curve: Curves.ease, duration: const Duration(microseconds: 500));
        _minuteController.animateToItem(selectedMinuteIndex,
            curve: Curves.ease, duration: const Duration(microseconds: 500));
        _dayPeriodController.animateToItem(selectedDayPeriodIndex,
            curve: Curves.ease, duration: const Duration(microseconds: 500));
      });
    }
  }

  void _initDateScrollView() {
    _hourScrollView = DateScrollView(
      key: const Key("hour"),
      dates: <String>[
        for (int i in _hours) i.toString().padLeft(2, '0'),
      ],
      controller: _hourController,
      options: widget.options,
      scrollViewOptions: widget.scrollViewOptions.hour,
      selectedIndex: selectedHourIndex,
      locale: widget.locale,
      onTap: (int index) => _hourController.jumpToItem(index),
      onChanged: (_) => _onTimeChanged(),
    );
    _minuteScrollView = DateScrollView(
      key: const Key("minute"),
      dates: <String>[
        for (int i in _minutes) i.toString().padLeft(2, '0'),
      ],
      controller: _minuteController,
      options: widget.options,
      scrollViewOptions: widget.scrollViewOptions.minute,
      selectedIndex: selectedMinuteIndex,
      locale: widget.locale,
      onTap: (int index) => _minuteController.jumpToItem(index),
      onChanged: (_) => _onTimeChanged(),
    );
    _dayPeriodScrollView = DateScrollView(
      key: const Key("dayPeriod"),
      dates: <String>[
        for (DayPeriod period in _dayPeriod) period.name.toUpperCase(),
      ],
      controller: _dayPeriodController,
      options: widget.options,
      scrollViewOptions: widget.scrollViewOptions.dayPeriod,
      selectedIndex: selectedDayPeriodIndex,
      locale: widget.locale,
      onTap: (int index) => _dayPeriodController.jumpToItem(index),
      onChanged: (_) => _onTimeChanged(),
    );
  }

  void _onTimeChanged() {
    setState(() {
      _selectedTime = TimeOfDay(
        hour: selectedDayPeriod == DayPeriod.am
            ? selectedHour
            : selectedHour + 12,
        minute: selectedMinute,
      );
    });
    widget.onTimeChanged(_selectedTime);
  }

  List<Widget> _getScrollDatePicker() {
    _initDateScrollView();

    // set order of scroll view
    if (widget.viewType?.isNotEmpty ?? false) {
      final viewList = <Widget>[];

      for (var view in widget.viewType!) {
        switch (view) {
          case TimePickerViewType.hour:
            viewList.add(_hourScrollView);
            break;
          case TimePickerViewType.minute:
            viewList.add(_minuteScrollView);
            break;
          case TimePickerViewType.dayPeriod:
            viewList.add(_dayPeriodScrollView);
            break;
        }
      }

      return viewList;
    }

    return [_hourScrollView, _minuteScrollView, _dayPeriodScrollView];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: widget.scrollViewOptions.mainAxisAlignment,
          crossAxisAlignment: widget.scrollViewOptions.crossAxisAlignment,
          children: _getScrollDatePicker(),
        ),
        // Date Picker Indicator
        IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.options.backgroundColor,
                        widget.options.backgroundColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              widget.indicator ??
                  Container(
                    height: widget.options.itemExtent,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.options.backgroundColor.withOpacity(0.7),
                        widget.options.backgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ViewType that represents order of scroll view
enum TimePickerViewType {
  hour,
  minute,
  dayPeriod,
}

class TimePickerScrollViewOptions {
  const TimePickerScrollViewOptions({
    this.hour = const ScrollViewDetailOptions(margin: EdgeInsets.all(4)),
    this.minute = const ScrollViewDetailOptions(margin: EdgeInsets.all(4)),
    this.dayPeriod = const ScrollViewDetailOptions(margin: EdgeInsets.all(4)),
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final ScrollViewDetailOptions hour;
  final ScrollViewDetailOptions minute;
  final ScrollViewDetailOptions dayPeriod;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  // Applies the given [ScrollViewDetailOptions] to all three options ie. year, month and day.
  static TimePickerScrollViewOptions all(ScrollViewDetailOptions value) {
    return TimePickerScrollViewOptions(
      hour: value,
      minute: value,
      dayPeriod: value,
    );
  }
}
