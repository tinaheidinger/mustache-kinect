import SimpleOpenNI.*;
import java.util.Date;

SimpleOpenNI context;
PImage mustache;
PImage razor;
boolean displayMustache = true;
boolean holdingRazor = true;

float mustacheX;
float mustacheY;
float razorX;
float razorY;

int lastTimeShaved = 0;

void setup() {
  size(640,480); // size of application window
  context = new SimpleOpenNI(this);
  context.enableDepth(); // receive data from depth sensor
  context.enableRGB(); // receive data from RGB sensor
  context.alternativeViewPointDepthToImage(); // align depth sensor to RGB sensor
  
  mustache = loadImage("mustache.png");
  razor = loadImage("razor.png");
  
  context.enableUser();
  context.setMirror(false);
}

void draw() {
  background(0); // clears window with black color to reduce artefacts
  context.update(); // asks kinect to send new data
  image(context.rgbImage(),0,0); // draw image from depth sensor at position 0-left 0-top
  //image(context.userImage(),0,0);
  
  int[] userList = context.getUsers(); // store list of users in an int array
  
  for(int i = 0; i < userList.length; i++) {
    println("Detected user #" + i);
    if (context.isTrackingSkeleton(userList[i])) {
      println("Skeleton detected");
      PVector head = new PVector();
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_HEAD, head);
      
      PVector convertedHead = new PVector();
      context.convertRealWorldToProjective(head, convertedHead);
      mustacheX = convertedHead.x-60;
      mustacheY = convertedHead.y;
      
      if((lastTimeShaved + 5000) < millis()) {
        displayMustache = true;
      }
      
      if (displayMustache) {
        image(mustache, mustacheX, mustacheY, 120, 30);
      }
      
      PVector rightHand = new PVector();
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, rightHand);
      PVector convertedRightHand = new PVector();
      context.convertRealWorldToProjective(rightHand, convertedRightHand);
      
      if (holdingRazor) {
        // draw razor onto right hand
        razorX = convertedRightHand.x-25;
        razorY = convertedRightHand.y-50;
        
        image(razor, razorX, razorY, 50, 100);
      } else {
        image(razor, 10, 10, 50, 100);
      }
      
      // detect collision between razor and mustache
      if (razorX > mustacheX && razorX < (mustacheX + 120) && razorY > mustacheY && razorY < (mustacheY + 30)) {
        displayMustache = false;
        lastTimeShaved = millis();
      }
    }
  }
}

void onNewUser(SimpleOpenNI curContext, int userId) {
  println("new user #" + userId);
  context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId) {
  println("lost user #" + userId);
  context.stopTrackingSkeleton(userId);
}

float getAbsoluteValue(float originalValue) {
  if (originalValue < 0) {
    return originalValue * (-1);
  } else {
    return originalValue;
  }
}