import SimpleOpenNI.*;
import java.util.Date;

SimpleOpenNI context;
PImage mustache;
PImage razor;
PImage mirrorImage;
boolean displayMustache = true;
boolean holdingRazor = true;

PGraphics mustacheLayer;

float mustacheX;
float mustacheY;
float razorX;
float razorY;

int lastTimeShaved = 0;

void setup() {
  size(640,480); // size of application window
  mustacheLayer = createGraphics(640, 480, JAVA3D);
  mustacheLayer.beginDraw();
  mustacheLayer.smooth();
  mustacheLayer.endDraw();
  context = new SimpleOpenNI(this);
  context.enableDepth(); // receive data from depth sensor
  context.enableRGB(); // receive data from RGB sensor
  context.alternativeViewPointDepthToImage(); // align depth sensor to RGB sensor
  
  mustache = loadImage("mustache.png");
  razor = loadImage("razor.png");
  mirrorImage = loadImage("spiegel.png");
  context.enableUser();
  context.setMirror(false);
 
  
}

void draw() {
  background(0); // clears window with black color to reduce artefacts
  context.update(); // asks kinect to send new data
  image(context.rgbImage(),0,0); // draw image from depth sensor at position 0-left 0-top
  //image(context.userImage(),0,0);
  
  int[] userList = context.getUsers(); // store list of users in an int array
  imageMode(CENTER);
  for(int i = 0; i < userList.length; i++) {
    //println("Detected user #" + i);
    if (context.isTrackingSkeleton(userList[i])) {
      //println("Skeleton detected");
      PVector head = new PVector();
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_HEAD, head);
      
      PVector convertedHead = new PVector();
      context.convertRealWorldToProjective(head, convertedHead);
      mustacheX = convertedHead.x;
      mustacheY = convertedHead.y + 30;
      println(convertedHead.z);
      float mustacheScale = map(convertedHead.z, 600, 1000, 0.0, 0.5);
      float mustacheWidth = 120 - mustacheScale * 120;
      float mustacheHeight = 30 - mustacheScale  * 30;
      
      
      if((lastTimeShaved + 5000) < millis()) {
        displayMustache = true;
      }
      
      if (displayMustache) {
        mustacheLayer.image(mustache, mustacheX, mustacheY, mustacheWidth, mustacheHeight);
        
      }
      
      PVector rightHand = new PVector();
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, rightHand);
      PVector convertedRightHand = new PVector();
      context.convertRealWorldToProjective(rightHand, convertedRightHand);
      
      if (holdingRazor) {
        // draw razor onto right hand
        razorX = convertedRightHand.x-25;
        razorY = convertedRightHand.y-50;
        
        //image(razor, razorX, razorY, 50, 100);
        
        // do any erasing here
        color c = color(0,0); // fully transparent
        fill(c);
        rectMode(CENTER);
        mustacheLayer.rect(razorX, razorY, 50, 100);
      } else {
        //image(razor, 10, 10, 50, 100);
      }
      
      // detect collision between razor and mustache
      if (razorX > mustacheX && razorX < (mustacheX + 120) && razorY > mustacheY && razorY < (mustacheY + 30)) {
        //displayMustache = false;
        lastTimeShaved = millis();
      }
    }
  }
  imageMode(CORNER);
  image(mirrorImage, 0, 0);
}

void onNewUser(SimpleOpenNI curContext, int userId) {
 // println("new user #" + userId);
  context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId) {
  //println("lost user #" + userId);
  context.stopTrackingSkeleton(userId);
  displayMustache = false;
}

float getAbsoluteValue(float originalValue) {
  if (originalValue < 0) {
    return originalValue * (-1);
  } else {
    return originalValue;
  }
}
