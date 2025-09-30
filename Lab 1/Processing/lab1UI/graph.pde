//Reads data from arduino, creates graph

import controlP5.*;
import processing.serial.*; 

ControlP5 cp5;
Serial myPort;
String inString = ""; 
int age = 9999;


//getters for confidence and Heartrate
int lastHR = 0;
int lastConf = 0;
int lastSpO2 = 0; //oxygen



class LineChart {
  int min = 0;
  int max = 220;
  IntList values;
  IntList colors;
  LineChart(int size){
    values = new IntList(size);
    colors = new IntList(size);
    for (int i=0; i < size; i++){
      values.append(60);
      colors.append(int(color(255)));
    }
  }
  void draw(int x, int y, int width, int height){
    fill(0,0,0);
    stroke(0,0,0);
    rect(x,y,width,height);
    for (int i=0; i < values.size()-1; i++){
      float leftPointX = i * (width/float(values.size()-1)) + x;
      float leftPointY = (max-values.get(i)) * (height/float(max-min)) + y;
      float rightPointX = (i+1) * (width/float(values.size()-1)) + x;
      float rightPointY = (max-values.get(i+1)) * (height/float(max-min)) + y;
      stroke(colors.get(i+1));
      line(leftPointX,leftPointY,rightPointX,rightPointY);
    }
  }
  void addShift(){
    int lastIndex = values.size()-1;
    addShift(values.get(lastIndex),colors.get(lastIndex));
  }
  void addShift(int v, color c){
    
    //line kept bleeding off graph so I added this
    v = constrain(v, min, max);      
    
    values.remove(0);
    values.append(v);
    colors.remove(0);
    colors.append(int(c));
  }
}

color RED = color(255,0,0);
color YELLOW = color(255,255,0);
color GREEN = color(0,255,0);
color BLUE = color(0,0,255);
color WHITE = color(255,255,255);

LineChart myChart;
Chart pieChart;
float[] pieChartData = {1,1,1,1,1};

void graphSetup(){
 // size(400,400);
  cp5 = new ControlP5(this);
  cp5.addTextfield("ageInput")
    .setPosition(40,20)
    .setAutoClear(false)
    ;
  pieChart = cp5.addChart("pieChart")
    .setPosition(300,25)
    .setView(Chart.PIE)
    .setSize(200,200)
    .addDataSet("data1")
    .setColors("data1",RED,YELLOW,GREEN,BLUE,WHITE)
    .setData("data1",pieChartData)
    ;
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 115200);
  //println(Serial.list()[1]);
  myPort.clear();
  
 //
 myPort.bufferUntil('\n');
  
  myChart = new LineChart(300);
}

public void ageInput(String theText){
  age = int(theText);
  pieChartData[0] = 0;
  pieChartData[1] = 0;
  pieChartData[2] = 0;
  pieChartData[3] = 0;
  pieChartData[4] = 0;
}

void graphDraw(){
  //myChart.addShift(int(random(20,120)),RED);
  
  myChart.draw(50,100,300,200);
  pieChart.setData("data1",pieChartData);
}

//void serialEvent(Serial p) { 
//  String temp = p.readString();
//  inString += temp;
//  if (temp.equals("}")){
//    //println(inString);
    
//    JSONObject json = parseJSONObject(inString);
//    if (json == null) {
//      println("JSONObject could not be parsed");
//    } else {
//      println(json);
//      //added getters
//      lastHR = json.getInt("HR");
//      lastConf = json.getInt("Conf"); 
//      lastSpO2 = json.getInt("SpO2"); 
      
//      if (json.getInt("Stat") == 3){
//        int heartPerformance = (lastHR*100)/(220-age);
//        if (heartPerformance >= 90){
//          myChart.addShift(lastHR,RED);
//          pieChartData[0]++;
//        } else if (heartPerformance >= 80){
//          myChart.addShift(lastHR,YELLOW);
//          pieChartData[1]++;
//        } else if (heartPerformance >= 70){
//          myChart.addShift(lastHR,GREEN);
//          pieChartData[2]++;
//        } else if (heartPerformance >= 60){
//          myChart.addShift(lastHR,BLUE);
//          pieChartData[3]++;
//        } else {
//          myChart.addShift(lastHR,WHITE);
//          pieChartData[4]++;
//        }
   
//      }else{
//        myChart.addShift();
//      }
      
//    }
//    // HR, Conf, Stat
//    // Stat needs to be 3
//    // Conf need to be not 0
//    inString = "";
    
//  }
  

//  /*
//  JSONObject json = parseJSONObject(inString);
//  if (json == null) {
//    println("JSONObject could not be parsed");
//  } else {
//    String species = json.getString("species");
//    println(species);
//  }
//  */
//} 

void serialEvent(Serial p) {
  String line = p.readStringUntil('\n');
  if (line == null) return;

  line = trim(line);
  if (line.length() == 0) return;

  // Ignore non-JSON noise (e.g., "Sensor started!" etc.)
  int s = line.indexOf('{');
  int e = line.lastIndexOf('}');
  if (s < 0 || e < s) {
    // println("NON-JSON:", line);  // uncomment to debug
    return;
  }

  String jsonStr = line.substring(s, e + 1);
  // println("JSON:", jsonStr);    // uncomment to debug

  JSONObject json = parseJSONObject(jsonStr);
  if (json == null) {
    println("JSON parse failed:", jsonStr);
    return;
  }

  // Safely pull fields (default to 0 if missing)
  lastHR   = json.hasKey("HR")   ? json.getInt("HR")   : 0;
  lastConf = json.hasKey("Conf") ? json.getInt("Conf") : 0;
  lastSpO2 = json.hasKey("SpO2") ? json.getInt("SpO2") : 0;
  int stat = json.hasKey("Stat") ? json.getInt("Stat") : 0;


  println(
    "HR:", lastHR,
    "Conf:", lastConf,
    "SpO2:", lastSpO2,
    "Stat:", stat
  );



  // Only push onto the chart if finger present & we have a sane age
  int maxHR = 220 - constrain(age, 0, 120);
  maxHR = max(100, maxHR); // avoid silly values

  if (stat == 3 && lastHR > 0) {
    int heartPerformance = int((lastHR * 100.0) / maxHR);
    if      (heartPerformance >= 90) { myChart.addShift(lastHR, RED);    pieChartData[0]++; }
    else if (heartPerformance >= 80) { myChart.addShift(lastHR, YELLOW); pieChartData[1]++; }
    else if (heartPerformance >= 70) { myChart.addShift(lastHR, GREEN);  pieChartData[2]++; }
    else if (heartPerformance >= 60) { myChart.addShift(lastHR, BLUE);   pieChartData[3]++; }
    else                             { myChart.addShift(lastHR, WHITE);  pieChartData[4]++; }
  } else {
    myChart.addShift();
  }
}


//getter functions 
int graphGetHR() {return lastHR;}
int graphGetConf() { return lastConf; }
int graphGetSpO2() { return lastSpO2; }
int graphGetIBI() {
  return (lastHR > 0) ? int(60000.0 / lastHR) : 0;  // ms between beats (approx)
}
