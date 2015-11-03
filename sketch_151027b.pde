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

int maxMustacheWidth = 120;
int maxMustacheHeight = 30;
int lastTimeShaved = 0;

void setup() {
  size(640,480); // size of application window
  mustacheLayer = createGraphics(maxMustacheWidth, maxMustacheHeight, JAVA2D);
  mustacheLayer.beginDraw();
  mustacheLayer.smooth();
  
  imageMode(CENTER);
  mustache = loadImage("mustache.png");
  mustacheLayer.image(mustache, 0, 0, maxMustacheWidth, maxMustacheHeight);
        
  mustacheLayer.endDraw();
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
        displayMustache = true;
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
        
        // do any erasing here
       
        mustacheLayer.beginDraw();
         color c = color(0,0); // fully transparent
         mustacheLayer.loadPixels();
         float mappedRazorX =  razorX- (mustacheX /*- mustacheWidth/2*/) ;
         float mappedRazorY =  razorY- (mustacheY /*- mustacheHeight/2*/) ;
         
         if (mappedRazorX < 0) println("RASIERER -> BART");
         if (mappedRazorX >= 0 && mappedRazorX < mustacheWidth) println("RASIERERBART");
         if (mappedRazorX >= mustacheWidth) println("BART -> RASIERER");
         
         for (int x=0; x<mustacheLayer.width; x++) {
           for (int y=0; y<mustacheLayer.height; y++) {
             float distance = dist(x, y, mappedRazorX, mappedRazorY);
             if (distance <= 25) {
               int loc = x + y*mustacheLayer.width;
               mustacheLayer.pixels[loc] = c;
               
             }
           }
         }
         
         mustacheLayer.updatePixels();
         mustacheLayer.ellipseMode(CORNER);
         mustacheLayer.stroke(0,0,255);
         mustacheLayer.strokeWeight(2);
         mustacheLayer.ellipse( mappedRazorX, mappedRazorY, 25, 25);
        //fill(0,0,0,0);
        //rectMode(CENTER);
        //mustacheLayer.rect(razorX, razorY, 50, 100);
        mustacheLayer.endDraw();
      } else {
        //image(razor, 10, 10, 50, 100);
      }
      image(mustacheLayer, mustacheX, mustacheY, mustacheWidth, mustacheHeight);
  
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
