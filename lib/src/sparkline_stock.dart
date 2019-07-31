import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui show PointMode;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'sparkline_model.dart';
import 'date_format_base.dart';

/// Strategy used when filling the area of a sparkline.
enum FillMode {
  /// Do not fill, draw only the sparkline.
  none,

  /// Fill the area above the sparkline: creating a closed path from the line
  /// to the upper edge of the widget.
  above,

  /// Fill the area below the sparkline: creating a closed path from the line
  /// to the lower edge of the widget.
  below,
}

/// Strategy used when drawing individual data points over the sparkline.
enum PointsMode {
  /// Do not draw individual points.
  none,

  /// Draw all the points in the data set.
  all,

  /// Draw only the last point in the data set.
  last,
}

/// A widget that draws a sparkline chart.
///
/// Represents the given [data] in a sparkline chart that spans the available
/// space.
///
/// By default only the sparkline is drawn, with its looks defined by
/// the [lineWidth], [lineColor], and [lineGradient] properties.
///
/// The corners between two segments of the sparkline can be made sharper by
/// setting [sharpCorners] to true.
///
/// The area above or below the sparkline can be filled with the provided
/// [fillColor] or [fillGradient] by setting the desired [fillMode].
///
/// [pointsMode] controls how individual points are drawn over the sparkline
/// at the provided data point. Their appearance is determined by the
/// [pointSize] and [pointColor] properties.
///
/// By default, the sparkline is sized to fit its container. If the
/// sparkline is in an unbounded space, it will size itself according to the
/// given [fallbackWidth] and [fallbackHeight].
class Sparkline extends StatefulWidget {
  /// Creates a widget that represents provided [data] in a Sparkline chart.
  Sparkline({
    Key key,
    @required this.data,
    this.lineWidth = 2.0,
    this.lineColor = Colors.lightBlue,
    this.lineGradient,
    this.pointsMode = PointsMode.none,
    this.pointSize = 4.0,
    this.pointColor = const Color(0xFF0277BD), //Colors.lightBlue[800]
    this.sharpCorners = false,
    this.fillMode = FillMode.none,
    this.fillColor = const Color(0xFF81D4FA), //Colors.lightBlue[200]
    this.fillGradient,
    this.fallbackHeight = 100.0,
    this.fallbackWidth = 300.0,
    this.enableGridLines = true,
    this.gridLineColor = Colors.grey,
    this.gridLineAmount = 5,
    this.gridLineWidth = 0.5,
    this.gridLineLabelColor = Colors.grey,
    this.allLength,
    this.yMax,
    this.yMin,
    this.labelPrefix = "",
  })  : assert(data != null),
        assert(lineWidth != null),
        assert(lineColor != null),
        assert(pointsMode != null),
        assert(pointSize != null),
        assert(pointColor != null),
        assert(sharpCorners != null),
        assert(fillMode != null),
        assert(fillColor != null),
        assert(fallbackHeight != null),
        assert(fallbackWidth != null),
        assert(allLength != null),
        super(key: key);

  /// List of values to be represented by the sparkline.
  ///
  /// Each data entry represents a single point on the chart, containing
  /// information such as the value of the point and the corresponding time,
  /// and plots a path to connect continuous points based on the point value
  /// to form sparkline.
  ///
  /// The values are normalized to fit within the bounds of the chart.
  final List<SparkLineStockModel> data;

  /// The width of the sparkline.
  ///
  /// Defaults to 2.0.
  final double lineWidth;

  ///The length of all the data
  ///
  ///This value does not equal [data] length
  final double allLength;

  ///Y-axis maximum
  ///
  final double yMax;

  ///Y-axis minimum
  ///
  final double yMin;

  /// The color of the sparkline.
  ///
  /// Defaults to Colors.lightBlue.
  ///
  /// This is ignored if [lineGradient] is non-null.
  final Color lineColor;

  /// A gradient to use when coloring the sparkline.
  ///
  /// If this is specified, [lineColor] has no effect.
  final Gradient lineGradient;

  /// Determines how individual data points should be drawn over the sparkline.
  ///
  /// Defaults to [PointsMode.none].
  final PointsMode pointsMode;

  /// The size to use when drawing individual data points over the sparkline.
  ///
  /// Defaults to 4.0.
  final double pointSize;

  /// The color used when drawing individual data points over the sparkline.
  ///
  /// Defaults to Colors.lightBlue[800].
  final Color pointColor;

  /// Determines if the sparkline path should have sharp corners where two
  /// segments intersect.
  ///
  /// Defaults to false.
  final bool sharpCorners;

  /// Determines the area that should be filled with [fillColor].
  ///
  /// Defaults to [FillMode.none].
  final FillMode fillMode;

  /// The fill color used in the chart, as determined by [fillMode].
  ///
  /// Defaults to Colors.lightBlue[200].
  ///
  /// This is ignored if [fillGradient] is non-null.
  final Color fillColor;

  /// A gradient to use when filling the chart, as determined by [fillMode].
  ///
  /// If this is specified, [fillColor] has no effect.
  final Gradient fillGradient;

  /// The width to use when the sparkline is in a situation with an unbounded
  /// width.
  ///
  /// See also:
  ///
  ///  * [fallbackHeight], the same but vertically.
  final double fallbackWidth;

  /// The height to use when the sparkline is in a situation with an unbounded
  /// height.
  ///
  /// See also:
  ///
  ///  * [fallbackWidth], the same but horizontally.
  final double fallbackHeight;

  /// Enable or disable grid lines
  final bool enableGridLines;

  /// Color of grid lines and label text
  final Color gridLineColor;
  final Color gridLineLabelColor;

  /// Number of grid lines
  final int gridLineAmount;

  /// Width of grid lines
  final double gridLineWidth;

  /// Symbol prefix for grid line labels
  final String labelPrefix;


  ///Current scale when use pinch/zoom
  double _currentScale = 0.01;

  ///This value allow us to get the last scale used when start the pinch/zoom again
  double _previousScale;

  @override
  _SparklineState createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline> with SingleTickerProviderStateMixin{

  AnimationController _animationController;
  ///Track the current position when dragging the indicator
  Offset _verticalIndicatorPosition;
  bool _displayIndicator = false;

  ///padding for leading and trailing of the chart
  final double horizontalPadding = 10.0;

  double _lastValueSnapped = double.infinity;
  bool get isPinchZoomActive => _touchFingers > 1;

  ///Refresh the position of the vertical/bubble
  _refreshPosition(details) {
    if (_animationController.status == AnimationStatus.completed &&
        _displayIndicator) {
      _updatePosition(details);
    }
  }

  ///Update and refresh the position based on the current screen
  _updatePosition(details) {
    setState(
          () {
        RenderBox renderBox = context.findRenderObject();
        final position = renderBox.globalToLocal(details.globalPosition);

        if (position != null) {
          final fixedPosition = Offset(
              position.dx - horizontalPadding,
              position.dy);
          _verticalIndicatorPosition = fixedPosition;
        }
      },
    );
  }

  ///After long press this method is called to display the bubble indicator if is not visible
  ///An animation and snap sound are triggered
  _onDisplayIndicator(details) {
    if (!_displayIndicator) {
      _displayIndicator = true;
      _animationController.forward(
        from: 0.0,
      );
    }
    _onDataPointSnap(double.maxFinite);
    _updatePosition(details);
  }

  ///When the current indicator reach any data point a feedback is triggered
  void _onDataPointSnap(double value) {
    if (_lastValueSnapped != value) {
      if (Platform.isIOS) {
        HapticFeedback.heavyImpact();
      } else {
        Feedback.forTap(context);
      }
      _lastValueSnapped = value;
    }
  }

  ///Hide the vertical/bubble indicator and refresh the widget
  _onHideIndicator() {
    if (_displayIndicator) {
      _animationController.reverse(from: 1.0).whenCompleteOrCancel(
            () {
          setState(
                () {
              _displayIndicator = false;
            },
          );
        },
      );
    }
  }

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 300,
      ),
    );
    setState(() {
    });
    super.initState();
  }

  @override
  void dispose() {
    _onHideIndicator();
    _animationController.dispose();
    super.dispose();
  }

  int _touchFingers = 0;

  @override
  Widget build(BuildContext context) {
    return new LimitedBox(
      maxWidth: widget.fallbackWidth,
      maxHeight: widget.fallbackHeight,
      child: Listener(
        onPointerDown: (_) {
          _touchFingers++;
          if (_touchFingers > 1) {
            setState(() {});
          }
        },
        onPointerUp: (_) {
          _touchFingers--;
          if (_touchFingers < 2) {
            setState(() {});
          }
        },
        child: GestureDetector(
          onLongPressStart: isPinchZoomActive ? null : _onDisplayIndicator,
          onLongPressMoveUpdate: isPinchZoomActive ? null : _refreshPosition,
          onScaleStart: (_) {
            widget._previousScale = widget._currentScale;
          },
//          onTap: isPinchZoomActive ? null : _onHideIndicator,
          onTapDown: _onDisplayIndicator,
          child: new CustomPaint(
            size: Size.infinite,
            painter: new _SparklinePainter(
                widget.data,
                lineWidth: widget.lineWidth,
                lineColor: widget.lineColor,
                lineGradient: widget.lineGradient,
                sharpCorners: widget.sharpCorners,
                fillMode: widget.fillMode,
                fillColor: widget.fillColor,
                fillGradient: widget.fillGradient,
                pointsMode: widget.pointsMode,
                pointSize: widget.pointSize,
                pointColor: widget.pointColor,
                enableGridLines: widget.enableGridLines,
                gridLineColor: widget.gridLineColor,
                gridLineAmount: widget.gridLineAmount,
                gridLineLabelColor: widget.gridLineLabelColor,
                gridLineWidth: widget.gridLineWidth,
                labelPrefix: widget.labelPrefix,
                allLength: widget.allLength,
                verticalIndicatorPosition: _verticalIndicatorPosition,
                showIndicator: _displayIndicator,
                animation: CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    0.0,
                    0.1,
                    curve: Curves.elasticOut,
                  ),
                ),
                max: widget.yMax,
                min: widget.yMin
            ),
          ),
        ),
      ),

    );
  }

}

class _SparklinePainter extends CustomPainter {

  final double radiusDotIndicatorItems = 3.5;
  List<SparkLineStockModel> _currentCustomValues = [];
  final double radiusDotIndicatorMain = 6;
  final Animation animation;
  List<TextPainter> gridLineTextPainters = [];
  final Offset verticalIndicatorPosition;
  final bool showIndicator;

  _SparklinePainter(
      this.dataPoints, {
        @required this.lineWidth,
        @required this.lineColor,
        this.lineGradient,
        @required this.sharpCorners,
        @required this.fillMode,
        @required this.fillColor,
        this.fillGradient,
        @required this.pointsMode,
        @required this.pointSize,
        @required this.pointColor,
        @required this.enableGridLines,
        this.gridLineColor,
        this.gridLineAmount,
        this.gridLineWidth,
        this.gridLineLabelColor,
        this.labelPrefix,
        this.allLength,
        @required this.max,
        @required this.min,
        this.verticalIndicatorPosition,
        this.showIndicator,
        this.animation,
      });//dataPoints.reduce(math.min);

  final List<SparkLineStockModel> dataPoints;
  final double lineWidth;

  final Color lineColor;
  final Gradient lineGradient;

  final bool sharpCorners;

  final FillMode fillMode;
  final Color fillColor;
  final Gradient fillGradient;

  final PointsMode pointsMode;
  final double pointSize;
  final Color pointColor;

  final double max;
  final double min;

  final bool enableGridLines;
  final Color gridLineColor;
  final int gridLineAmount;
  final double gridLineWidth;
  final Color gridLineLabelColor;
  final String labelPrefix;
  final double allLength;


  update() {
    if (enableGridLines) {
      double gridLineValue;
      for (int i = 0; i < gridLineAmount; i++) {
        // Label grid lines
        gridLineValue = max - (((max - min) / (gridLineAmount - 1)) * i);

        String gridLineText;
        if (gridLineValue < 1) {
          gridLineText = gridLineValue.toStringAsPrecision(4);
        } else if (gridLineValue < 999) {
          gridLineText = gridLineValue.toStringAsFixed(2);
        } else {
          gridLineText = gridLineValue.round().toString();
        }

        gridLineTextPainters.add(new TextPainter(
            text: new TextSpan(
                text: labelPrefix + gridLineText,
                style: new TextStyle(
                    color: gridLineLabelColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold
                )
            ),
            textDirection: TextDirection.ltr));
        gridLineTextPainters[i].layout();
      }
    }
  }

  ///return the real value of canvas
  _getRealValue(double value, double maxConstraint, double maxValue) =>
      maxConstraint * value / (maxValue == 0 ? 1 : maxValue);

  @override
  void paint(Canvas canvas, Size size) {

    //in the component, the real-time width of the line graph
    double realTimeWidth = size.width*(dataPoints.length/allLength) - lineWidth;

    Paint paintVerticalIndicator = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    Paint paintControlPoints = Paint()..strokeCap = StrokeCap.round;

    final double height = size.height - lineWidth;
    final double heightNormalizer = height / (max - min);

    final Path path = new Path();
    final List<Offset> points = <Offset>[];

    Offset startPoint;

    _AxisValue lastPoint = _AxisValue(
      x: 0,
      y: height,
    );

    if (gridLineTextPainters.isEmpty) {
      update();
    }

    double verticalX = 0.0;
    double verticalY = 0.0;
    //fixing verticalIndicator outbounds
    if (verticalIndicatorPosition != null) {
      verticalX = verticalIndicatorPosition.dx  + 10;
      verticalY = verticalIndicatorPosition.dy  + 0;
      if (verticalIndicatorPosition.dx < 0) {
        verticalX = 0.0;
      } else if (verticalIndicatorPosition.dx > realTimeWidth) {
        verticalX = realTimeWidth;
      }
    }

    if (enableGridLines) {
      realTimeWidth = size.width - gridLineTextPainters[0].text.text.length * 6;
      Paint gridPaint = new Paint()
        ..color = gridLineColor
        ..strokeWidth = gridLineWidth;

      double gridLineDist = height / (gridLineAmount - 1);
      double gridLineY;

      // Draw grid lines
      for (int i = 0; i < gridLineAmount; i++) {
        gridLineY = (gridLineDist * i).round().toDouble();
        canvas.drawLine(new Offset(0.0, gridLineY),
            new Offset(realTimeWidth, gridLineY), gridPaint);

        // Label grid lines
        gridLineTextPainters[i]
            .paint(canvas, new Offset(realTimeWidth + 2.0, gridLineY - 6.0));
      }
    }

//    final double widthNormalizer = realTimeWidth / dataPoints.length;
    final double widthNormalizer = realTimeWidth / allLength;

    //variables for the last item on the list (this is required to display the indicator)
    Offset p0, p1, p2, p3;

    for (int index = 0; index < dataPoints.length; index++) {
      double x = index * widthNormalizer + lineWidth / 2;
      double y = height - (dataPoints[index].value - min) * heightNormalizer + lineWidth / 2;

      if (pointsMode == PointsMode.all) {
        points.add(new Offset(x, y));
      }

      if (pointsMode == PointsMode.last && index == dataPoints.length - 1) {
        points.add(new Offset(x, y));
      }

      if (index == 0) {
        startPoint = new Offset(x, y);
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      final double valueX = x;//_getRealValue(x, size.width, dataPoints.length.toDouble());
      final double valueY = y;//size.height - _getRealValue(dataPoints[index], size.height, max);

      final double controlPointX = valueX;// + (valueX - lastPoint.x) / 2;

      if (verticalIndicatorPosition != null &&
          verticalX >= lastPoint.x &&
          verticalX <= valueX) {
        //points to draw the info
        p0 = Offset(lastPoint.x, height - lastPoint.y);
        p1 = Offset(controlPointX, height - lastPoint.y);
        p2 = Offset(controlPointX, height - valueY);
        p3 = Offset(valueX, height - valueY);
      }

      if (verticalIndicatorPosition != null) {
        //get current information
        double nextX = double.infinity;
        double lastX = double.negativeInfinity;
        if (dataPoints.length > (index + 1)) {
          nextX = (index + 1) * widthNormalizer + lineWidth / 2;//_getRealValue(dataPoints[i + 1], size.width, allLength);
        }
        if (index > 0) {
          lastX = (index - 1) * widthNormalizer + lineWidth / 2;//_getRealValue(dataPoints[i - 1], size.width, allLength);
        }

        //if vertical indicator is in range then display the bubble info
        if (verticalX >= valueX - (valueX - lastX) / 2 &&
            verticalX <= valueX + (nextX - valueX) / 2) {

          if (_currentCustomValues.length < allLength) {
            if (_currentCustomValues.length > 0) {
              _currentCustomValues.clear();
            }
            _currentCustomValues.add(dataPoints[index]);
          }
        }
      }

    }

    Paint paint = new Paint()
      ..strokeWidth = lineWidth
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = sharpCorners ? StrokeJoin.miter : StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (lineGradient != null) {
      final Rect lineRect = new Rect.fromLTWH(0.0, 0.0, realTimeWidth, height);
      paint.shader = lineGradient.createShader(lineRect);
    }

    if (fillMode != FillMode.none) {
      Path fillPath = new Path()..addPath(path, Offset.zero);
      if (fillMode == FillMode.below) {
        fillPath.relativeLineTo(lineWidth / 2, 0.0);
        fillPath.lineTo(widthNormalizer*dataPoints.length, size.height);
        fillPath.lineTo(0.0, size.height);
        fillPath.lineTo(startPoint.dx - lineWidth / 2, startPoint.dy);
      } else if (fillMode == FillMode.above) {
        fillPath.relativeLineTo(lineWidth / 2, 0.0);
        fillPath.lineTo(realTimeWidth, 0.0);
        fillPath.lineTo(0.0, 0.0);
        fillPath.lineTo(startPoint.dx - lineWidth / 2, startPoint.dy);
      }
      fillPath.close();

      Paint fillPaint = new Paint()
        ..strokeWidth = 0.0
        ..color = fillColor
        ..style = PaintingStyle.fill;

      if (fillGradient != null) {
        final Rect fillRect = new Rect.fromLTWH(0.0, 0.0, realTimeWidth, height);
        fillPaint.shader = fillGradient.createShader(fillRect);
      }
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, paint);

    if (points.isNotEmpty) {
      Paint pointsPaint = new Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = pointSize
        ..color = pointColor;
      canvas.drawPoints(ui.PointMode.points, points, pointsPaint);
    }

    if (verticalIndicatorPosition != null && showIndicator) {

      if (p0 != null) {
        final yValue = _getYValues(
          p0,
          p1,
          p2,
          p3,
          (verticalX - p0.dx) / (p3.dx - p0.dx),
        );

        double infoWidth = 0; //base value, modified based on the label text
        double infoHeight = 85;

        //bubble indicator padding
        final horizontalPadding = 20.0;
        final verticalPadding = 25.0;

        double offsetInfo = 55 + ((_currentCustomValues.length - 1.0) * 10.0);
        final centerForCircle = Offset(verticalX, height - yValue);
//        final centerForCircle = Offset(verticalX, verticalY);
        final center = Offset(verticalX, verticalY);

        canvas.drawLine(
          Offset(verticalX, height),
          Offset(verticalX, 0),
          paintVerticalIndicator,
        );

        //draw point
//        canvas.drawCircle(
//          centerForCircle,
//          radiusDotIndicatorMain,
//          Paint()
//            ..color = Colors.deepOrange
//            ..strokeWidth = 1.0,
//        );

        //calculate the total lenght of the lines
        List<TextSpan> textValues = [];
        List<Offset> centerCircles = [];

        double space = 10 - ((infoHeight / (8.75)) * _currentCustomValues.length);
        infoHeight = infoHeight + (_currentCustomValues.length - 1) * (infoHeight / 3);

        for (SparkLineStockModel customValue in _currentCustomValues.reversed.toList()) {

          textValues.add(
            TextSpan(
              text: "时间：${customValue.time}\n",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              children: [
                TextSpan(
                  text: "价格：${customValue.value}\n",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                TextSpan(
                  text: "涨跌:${customValue.riseAndFall}\n",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                TextSpan(
                  text: "涨跌幅:${customValue.amplitude}\n",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
          centerCircles.add(
            // Offset(center.dx - infoWidth / 2 + radiusDotIndicatorItems * 1.5,
            Offset(
                center.dx,
                center.dy - offsetInfo - radiusDotIndicatorItems + space + (_currentCustomValues.length == 1 ? 1 : 0)),
          );
          space += 12.5;
        }


        if (animation.isCompleted) {

          //Calculate Text size
          TextPainter textPainter = TextPainter(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: _getTimeTitleText(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 9.5,
              ),
              children: textValues,
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();

          infoWidth = textPainter.width + radiusDotIndicatorItems * 2 + horizontalPadding;

          final paintInfo = Paint()
            ..color = Colors.brown
            ..style = PaintingStyle.fill;

          //Draw Bubble info
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              _fromCenter(
                center:Offset(
                  (center.dx + infoWidth) > size.width ?
                  (center.dx - offsetInfo * animation.value) :
                  (center.dx + offsetInfo * animation.value),
                  (center.dy - infoHeight) > 0 ?
                  (center.dy - offsetInfo * animation.value) :
                  (center.dy + offsetInfo * animation.value),
                ),
                width: infoWidth,
                height: infoHeight,
              ),
              Radius.circular(5),
            ),
            paintInfo,
          );

          //Paint Text , title and description
          textPainter.paint(
            canvas,
            Offset(
              (center.dx + infoWidth) > size.width ? (center.dx -infoWidth) : (center.dx + 13),
              (center.dy - infoHeight) > 0 ?
              (center.dy - offsetInfo - infoHeight / 2.5) :
              (center.dy + offsetInfo - infoHeight / 2.5),
            ),
          );
        }
      }
    }

  }

  String _getTimeTitleText() {
    DateTime now = DateTime.now();
    String time = formatDate(now, [yyyy, '年', mm, '月', dd, '日']);
    return "${time}\n";
  }

  _getYValues(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    if (t.isNaN) {
      t = 1.0;
    }
    //P0 = (X0,Y0)
    //P1 = (X1,Y1)
    //P2 = (X2,Y2)
    //P3 = (X3,Y3)
    //X(t) = (1-t)^3 * X0 + 3*(1-t)^2 * t * X1 + 3*(1-t) * t^2 * X2 + t^3 * X3
    //Y(t) = (1-t)^3 * Y0 + 3*(1-t)^2 * t * Y1 + 3*(1-t) * t^2 * Y2 + t^3 * Y3
    //source: https://stackoverflow.com/questions/8217346/cubic-bezier-curves-get-y-for-given-x
    final y0 = p0.dy; // x0 = p0.dx;
    final y1 = p1.dy; //x1 = p1.dx,
    final y2 = p2.dy; //x2 = p2.dx,
    final y3 = p3.dy; //x3 = p3.dx,

    //print("p0: $p0, p1: $p1, p2: $p2, p3: $p3 , t: $t");

    final y = pow(1 - t, 3) * y0 +
        3 * pow(1 - t, 2) * t * y1 +
        3 * (1 - t) * pow(t, 2) * y2 +
        pow(t, 3) * y3;
    return y;
  }

  Rect _fromCenter({Offset center, double width, double height}) =>
      Rect.fromLTRB(
        center.dx - width / 2,
        center.dy - height / 2,
        center.dx + width / 2,
        center.dy + height / 2,
      );

  @override
  bool shouldRepaint(_SparklinePainter old) {
    return dataPoints != old.dataPoints ||
        lineWidth != old.lineWidth ||
        lineColor != old.lineColor ||
        lineGradient != old.lineGradient ||
        sharpCorners != old.sharpCorners ||
        fillMode != old.fillMode ||
        fillColor != old.fillColor ||
        fillGradient != old.fillGradient ||
        pointsMode != old.pointsMode ||
        pointSize != old.pointSize ||
        pointColor != old.pointColor ||
        enableGridLines != old.enableGridLines ||
        gridLineColor != old.gridLineColor ||
        gridLineAmount != old.gridLineAmount ||
        gridLineWidth != old.gridLineWidth ||
        gridLineLabelColor != old.gridLineLabelColor ||
        verticalIndicatorPosition != old.verticalIndicatorPosition ||
        showIndicator != old.showIndicator;
  }
}

class _AxisValue {
  final double x;
  final double y;
  const _AxisValue({
    this.x,
    this.y,
  });
}

//class _CustomValue {
//  final String value; //价格
//  final String time; //时间
//  final String riseAndFall; //涨跌
//  final String amplitude; //涨跌幅
//
//  _CustomValue({
//    @required this.value,
//    @required this.time,
//    @required this.riseAndFall,
//    @required this.amplitude,
//  });
//}