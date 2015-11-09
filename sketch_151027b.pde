import SimpleOpenNI.*;
import java.util.Date;

SimpleOpenNI context;
PImage mustache;
PImage razor;
PImage mirrorImage;
boolean displayMustache = true;
boolean holdingRazor = true;
boolean mustacheVisible = true;

PGraphics mustacheLayer;

float mustacheX;
float mustacheY;
float razorX;
float razorY;

boolean fadingIn = false;
boolean fadingOut = false;

int maxMustacheWidth = 120;
int maxMustacheHeight = 30;
int lastTimeShaved = 0;

float mustacheTransparency = 1;
float fadeLength = 60; // number of frames to complete one fading cycle
int currentFadeFrame = 0;
float fadeRate = 0.1;

void startFadeInMustache() {
  fadingIn = true;
  fadingOut = false;
  
  mustacheTransparency = 0;
  fadeRate = 1 / fadeLength;
  currentFadeFrame = 0;
}
void startFadeOutMustache() {
  //println("START FADEOUT");
  
  fadingIn = false;
  fadingOut = true;
  mustacheTransparency = 1;
  fadeRate = 1 / fadeLength;
    //println(fadeRate);
  currentFadeFrame = 0;
}
void doFadeInMustache() {
  // call every time the frame needs to decrease opacity
  if (currentFadeFrame <= fadeLength) {
    mustacheTransparency = min((mustacheTransparency + fadeRate), 1);
    currentFadeFrame++;
  }
  else {
    mustacheVisible = true;
    fadingIn = false;
  }
}
void doFadeOutMustache() {
  if (currentFadeFrame <= fadeLength) {
    mustacheTransparency = max((mustacheTransparency - fadeRate), 0);
    //println(mustacheTransparency);
    currentFadeFrame++;
  }
  else  {
    mustacheVisible = false;
    fadingOut = false;
    //println("END FADEOUT");
  }
}
void setup() {
  size(640,480); // size of application window
  //mustacheLayer = createGraphics(maxMustacheWidth, maxMustacheHeight, JAVA2D);
 // mustacheLayer.beginDraw();
 // mustacheLayer.smooth();
  
  //imageMode(CENTER);
  mustache = loadImage("mustache.png");
  //mustacheLayer.image(mustache, 0, 0, maxMustacheWidth, maxMustacheHeight);
        
  //mustacheLayer.endDraw();
  context = new SimpleOpenNI(this);
  context.enableDepth(); // receive data from depth sensor
  context.enableRGB(); // receive data from RGB sensor
  context.alternativeViewPointDepthToImage(); // align depth sensor to RGB sensor
  
  
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
      //println(convertedHead.z);
      float mustacheScale = map(convertedHead.z, 1000, 2000, 0.0, 0.5);
      float mustacheWidth = 120 - mustacheScale * 120;
      float mustacheHeight = 30 - mustacheScale  * 30;
      
      
      if((lastTimeShaved + 5000) < millis()) {
        //mustacheVisible = true;
       // startFadeInMustache();
       mustacheVisible = true;
       fadingIn = false;
       fadingOut = false;
      }
      
      if (displayMustache) {
        //mustacheLayer.beginDraw();
        //mustacheLayer.image(mustache, mustacheX, mustacheY, mustacheWidth, mustacheHeight);
        //mustacheLayer.endDraw();
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
        //image(razor, 10, 10, 50, 100);
      }
      if (mustacheVisible && !(fadingIn||fadingOut)) tint(255, 255);
      else tint(255, 255*mustacheTransparency);
      //println(mustacheX + " "  + mustacheY);
      
      
      println("MustacheVisible: " + mustacheVisible);
      println("FadingIN: " +fadingIn);
      println("FadingOUT: " + fadingOut);
      if (mustacheVisible || fadingIn || fadingOut) image(mustache, mustacheX, mustacheY, mustacheWidth, mustacheHeight);
      tint(255, 255);
      // detect collision between razor and mustache
      if (razorX > (mustacheX - (mustacheWidth/2)) && razorX < (mustacheX + (mustacheWidth/2)) && razorY > (mustacheY + (mustacheHeight/2)) && razorY < ( (mustacheY + mustacheY / 2) + 30)) {
        //displayMustache = false;
       //println("COLLIDE");
        if ((!fadingOut) && mustacheVisible) {
          
          startFadeOutMustache();
          lastTimeShaved = millis();
        }
        
      }
      if (fadingOut) doFadeOutMustache();
      else if (fadingIn) doFadeInMustache();
      //println(mustacheTransparency);
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

void onCreateHands(int handId,PVector pos,float time) {
  println("Created hand #" + handId);
}

void onDestroyHands(int handId,float time) {
  println("Destroyed hand #" + handId);
}

float getAbsoluteValue(float originalValue) {
  if (originalValue < 0) {
    return originalValue * (-1);
  } else {
    return originalValue;
  }
}
