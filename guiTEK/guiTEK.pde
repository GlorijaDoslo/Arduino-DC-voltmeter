import controlP5.*;
import meter.*;
import processing.serial.*;
import grafica.*;
import java.util.Arrays;

color backgroundColor = color(153, 255, 255);
color textColor = color(0, 0, 0);

Meter m, m2;
Serial port;
GPlot plot;
ControlP5 cp5;
DropdownList d1;

String arduinoPortName;
String portName;


boolean newData = true;
int xPos = 0;
boolean rectOver = false;
boolean begin = true;
boolean arduinoConnected = false;
boolean portLost = false;

int rectX, rectY, rectWidth, rectHeight;
color rectHighlight = color(204);
color rectColor = color(255);
String[] lastComList;


void setup() {
  lastComList = Serial.list();
  portName = Serial.list()[0]; //0 as default
  port = new Serial(this, portName, 9600);
  //port.bufferUntil('\n');

  size(1200, 950);
  background(backgroundColor);
  cp5 = new ControlP5(this);

  PFont pfont = createFont("Arial", 10, true); //Create a font
  ControlFont font = new ControlFont(pfont, 20); //font, font-size

  d1 = cp5.addDropdownList("myList-d1")
    .setPosition(width - 120, height/2)
    .setSize(100, 200)
    .setHeight(210)
    .setItemHeight(40)
    .setBarHeight(50)
    .setFont(font)
    .setColorBackground(color(60))
    .setColorActive(color(255, 128))
    ;

  d1.getCaptionLabel().set("PORT"); //set PORT before anything is selected



  m = new Meter(this, 25, 50);

  int mx = m.getMeterX();
  int my = m.getMeterY();
  int mw = m.getMeterWidth();
  int mh = m.getMeterHeight();

  m.setTitleFontName("Arial bold");
  m.setTitle("Napon skala [0, 5]");

  m.setScaleFontColor(color(200, 30, 70));
  m.setDisplayDigitalMeterValue(true);

  m.setArcColor(color(141, 113, 178));
  m.setArcThickness(5);
  //String[] scaleLabels1 = {"0", "1", "2", "3", "4", "5"};
  //m.setScaleLabels(scaleLabels1);
  m.setMinScaleValue(0);
  m.setMaxScaleValue(5);
  m.setMinInputSignal(-9);
  m.setMaxInputSignal(9);


  m2 = new Meter(this, width - mx - m.getMeterWidth(), my);
  m2.setTitleFontName("Arial bold");
  m2.setTitle("Napon skala [-9, 9]");
  String[] scaleLabels = { "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"};
  //String[] scaleLabels = { "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1",
  //  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"};
  m2.setScaleLabels(scaleLabels);
  m2.setScaleFontColor(color(200, 30, 70));
  m2.setDisplayDigitalMeterValue(true);

  m2.setArcColor(color(141, 113, 178));
  m2.setArcThickness(5);

  m2.setMinScaleValue(-10);
  m2.setMaxScaleValue(10);
  m2.setMinInputSignal(-9);
  m2.setMaxInputSignal(9);

  int m2x = m2.getMeterX();
  int m2y = m2.getMeterY();
  int m2w = m2.getMeterWidth();
  int m2h = m2.getMeterHeight();


  plot = new GPlot(this);
  plot.setPos(20, my + mh + 80);
  plot.setDim(800, 400);
  plot.setPointColor(color(0, 0, 0, 255));
  plot.setPointSize(2);
  plot.setTitleText("Grafik");
  plot.getXAxis().getAxisLabel().setText("Vreme");
  plot.getYAxis().getAxisLabel().setText("Napon");
  plot.drawGridLines(GPlot.BOTH);
  plot.setGridLineColor(color(0, 0, 0));
  plot.activateZooming(2, CENTER, CENTER);
  plot.activateReset();  // desni klik misem na grafik
  plot.activatePanning();
  plot.setYLim(-10, 10);
  //plot.setXLim(0, 20);
  plot.setVerticalAxesNTicks(18);

  rectWidth = 80;
  rectHeight = 40;
  rectX = width - rectWidth;
  rectY = height - rectHeight;

  background(backgroundColor);
  textSize(60);
  textAlign(CENTER);
  fill(textColor);
  text(0, mx + mw/2, my + mh + 50);
  text(0, m2x + m2w/2, m2y + m2h + 50);

  thread("DropListThread");
  thread("portsListThread");
}  // kraj setup-a

void draw() {
  if (begin) {
    m.updateMeter(0);
    m2.updateMeter(0);
    plot.defaultDraw();
    update();
  }

  if (!arduinoConnected || portLost) {
    fill(backgroundColor);
    stroke(backgroundColor);
    rect(width - 2*rectWidth - 115, height/2 - 80, 4*rectWidth, rectHeight + 30);
    fill(textColor);
    textSize(20);
    textAlign(CENTER);
    if (portLost)
      text("Arduino izgubljen!\nIzaberite port.", width - 2*rectWidth + 20, height/2 - 60);

    else {
      text("Nema konekcije sa Arduinom!\nIzaberite port.", width - 2*rectWidth + 20, height/2 - 60);
    }
  }

  int mx = m.getMeterX();
  int my = m.getMeterY();
  int mw = m.getMeterWidth();
  int mh = m.getMeterHeight();

  int m2x = m2.getMeterX();
  int m2y = m2.getMeterY();
  int m2w = m2.getMeterWidth();
  int m2h = m2.getMeterHeight();


  String str = "";
  String[] tokens;
  if (port.available() > 0) {
    str = port.readStringUntil('\n');

    if (str != null) {

      tokens = split(str, ',');
      if (tokens.length == 2) {
        float voltage = float(tokens[1]);

        if (newData) {
          background(backgroundColor);
          textSize(60);
          textAlign(CENTER);

          float val = (float(tokens[0]) / 745.0) * 5;
          float val2 = (float(tokens[0]) / 745.0 * 18) - 9;
          m2.updateMeter((int)val2);
          m.updateMeter((int)voltage);
          fill(textColor);
          text(val, mx + mw/2, my + mh + 50);
          text(voltage, m2x + m2w/2, m2y + m2h + 50);
          if (xPos > 300) {
            while (xPos > 0) {
              plot.removePoint(--xPos);
            }
          }

          plot.addPoint(xPos++, voltage);
          plot.defaultDraw();
        }  //kraj if-a newData
      }
      //fill(backgroundColor);
      //stroke(backgroundColor);
      //rect(0, height - rectHeight, 400, rectHeight);

      fill(textColor);
      textSize(20);
      textAlign(LEFT);
      if (plot.isOverBox(mouseX, mouseY)) {
        float[] value = plot.getValueAt(mouseX, mouseY);
        text("x = " + value[0] + ", y = " + value[1], 0, height - 20);
      }
      update();
    }
  }  // kraj if-a port.available
}  // kraj draw-a

boolean overRect(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width &&
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void update() {
  if (overRect(rectX, rectY, rectWidth, rectHeight)) {
    rectOver = true;
    fill(rectHighlight);
  } else {
    rectOver = false;
    fill(rectColor);
  }
  stroke(255);
  rect(rectX, rectY, rectWidth, rectHeight);
  textAlign(CENTER);
  fill(textColor);
  textSize(18);
  text("Zaustavi", rectX + rectWidth / 2, rectY + rectHeight / 2);
}

boolean pressedOnce = true;
void mousePressed() {

  if (rectOver && pressedOnce) {
    newData = false;
    pressedOnce = false;
    fill(backgroundColor);
    stroke(backgroundColor);
    rect(rectX - 3*rectWidth, rectY, 3*rectWidth, rectHeight);
    fill(textColor);
    textSize(20);
    text("Zaustavljeno!", width - rectWidth - rectWidth, height - 10);
  } else if (rectOver && !pressedOnce) {
    newData = true;
    pressedOnce = true;
  }
}

void controlEvent(ControlEvent theEvent) { //when something in the list is selected
  port.clear(); //delete the port
  port.stop(); //stop the port
  begin = false;
  if (theEvent.isController() && d1.isMouseOver()) {
    portName = Serial.list()[int(theEvent.getController().getValue())]; //port name is set to the selected port in the dropDownMeny
    port = new Serial(this, portName, 9600); //Create a new connection
    delay(1000);  // ceka arduino
    if (port.readStringUntil('\n') == null) {
      arduinoConnected = false;
    } else {
      arduinoPortName = portName;
      arduinoConnected = true;
    }
    //delay(2000);
  }
}

void DropListThread() {
  println("DropListThread started");
  while (true) {
    if (d1.isMouseOver()) {
      d1.clear(); //Delete all the items
      for (int i=0; i<Serial.list().length; i++) {
        d1.addItem(Serial.list()[i], i); //add the items in the list
      }
    }
    delay(800);
  }
}

void portsListThread() {
  println("portsListThread started");
  while (true) {
    println("proveravam uslov");
    String[] tempList = Serial.list();
    if (!Arrays.equals(lastComList, tempList)
      && !Arrays.asList(tempList).contains(arduinoPortName)) {
      println("Arduino izgubljen");
      portLost = true;
    }
    if (Arrays.equals(lastComList, tempList) && portLost) {
      portLost = false;
    }
    delay(3000);
  }
}
