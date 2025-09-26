//Reads data from arduino, creates graph

import controlP5.*;
import processing.serial.*; 

ControlP5 cp5;
Serial myPort;
String inString = ""; 


//getters for confidence and Heartrate
int lastHR = 0;
int lastConf = 0;
//need blood oxygen level, interval between heart beats


class LineChart {
  int min = 20;
  int max = 120;
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

LineChart myChart;

void graphSetup(){
 // size(400,400);
  cp5 = new ControlP5(this);
  cp5.addTextfield("age")
    .setPosition(40,20)
    .setAutoClear(false)
    ;
  
  
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.clear();
  
  myChart = new LineChart(300);
}

void graphDraw(){
  //myChart.addShift(int(random(20,120)),RED);
  myChart.draw(50,100,300,200);
  //println("Hello world");
  //printArray(Serial.list());
}

void serialEvent(Serial p) { 
  String temp = p.readString();
  inString += temp;
  if (temp.equals("}")){
    //println(inString);
    
    JSONObject json = parseJSONObject(inString);
    if (json == null) {
      println("JSONObject could not be parsed");
    } else {
      println(json);
      myChart.addShift(json.getInt("HR"),RED);
      
      //added getters
      lastHR = json.getInt("HR");
      lastConf = json.getInt("Conf"); 
    }
    // HR, Conf, Stat
    // Stat needs to be 3
    // Conf need to be not 0
    inString = "";
  }
  

  /*
  JSONObject json = parseJSONObject(inString);
  if (json == null) {
    println("JSONObject could not be parsed");
  } else {
    String species = json.getString("species");
    println(species);
  }
  */
} 

//getter functions 
int graphGetHR() {return lastHR;}
int graphGetConf() { return lastConf; }
