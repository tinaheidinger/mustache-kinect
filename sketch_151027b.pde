import SimpleOpenNI.*;

SimpleOpenNI context;

// images
PImage mustache;
PImage razor;
PImage mirrorImage;

boolean displayMustache = true;
boolean holdingRazor = false;
boolean mustacheVisible = true;

// mustache data
float mustacheX;
float mustacheY;
int maxMustacheWidth = 120;
int maxMustacheHeight = 30;

// razor data
float razorX;
float razorY;
float razorWidth = 50;
float razorHeight = 100;

// razor storage data
float razorStorageX = 520;
float razorStorageY = 170;
float razorStorageWidth = 50;
float razorStorageHeight = 100;

// shaving animation data
boolean fadingIn = false;
boolean fadingOut = false;

float mustacheTransparency = 1;
float fadeLength = 60; // number of frames to complete one fading cycle
int currentFadeFrame = 0;
float fadeRate = 0.1;

int lastTimeShaved = 0;

// shaving animation trigger
void startFadeOutMustache() {  
  fadingIn = false;
  fadingOut = true;
  mustacheTransparency = 1;
  fadeRate = 1 / fadeLength;
  currentFadeFrame = 0;
}

// completes one fading step
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

// completes one fading step
void doFadeOutMustache() {
  if (currentFadeFrame <= fadeLength) {
    mustacheTransparency = max((mustacheTransparency - fadeRate), 0);
    currentFadeFrame++;
  }
  else  {
    mustacheVisible = false;
    fadingOut = false;
  }
}
void setup() {
  size(640,480); // size of application window
  
  // load images
  mustache = loadImage("mustache.png");
  razor = loadImage("razor.png");
  mirrorImage = loadImage("spiegel.png");
        
  context = new SimpleOpenNI(this);
  context.enableDepth(); // receive data from depth sensor
  context.enableRGB(); // receive data from RGB sensor
  context.alternativeViewPointDepthToImage(); // align depth sensor to RGB sensor
  context.enableUser();
  context.setMirror(false);
}

void draw() {
  background(0); // clears window with black color to reduce artefacts
  context.update(); // asks kinect to send new data
  image(context.rgbImage(),0,0); // draw image from depth sensor at position 0-left 0-top
  
  int[] userList = context.getUsers(); // store list of users in an int array
  imageMode(CENTER);
  for(int i = 0; i < userList.length; i++) {
    if (context.isTrackingSkeleton(userList[i])) {
      // tracking user #i
      PVector head = new PVector();
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_HEAD, head);
      
      // convert tracked head from real into application coordinates
      PVector convertedHead = new PVector();
      context.convertRealWorldToProjective(head, convertedHead);
      mustacheX = convertedHead.x;
      mustacheY = convertedHead.y + 30; // offset for positioning mustache
      
      // scale mustache depending on user's distance from the sensor
      float mustacheScale = map(convertedHead.z, 1000, 2000, 0.0, 0.5);
      float mustacheWidth = 120 - mustacheScale * 120;
      float mustacheHeight = 30 - mustacheScale  * 30;
      
      // redisplay mustache 5 seconds after shaving
      if((lastTimeShaved + 5000) < millis()) {
       mustacheVisible = true;
       fadingIn = false;
       fadingOut = false;
      }
      
      // track right hand
      PVector rightHand = new PVector();
      context.getJointPositionSkeleton(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND, rightHand);
      PVector convertedRightHand = new PVector();
      context.convertRealWorldToProjective(rightHand, convertedRightHand);
      
      if (holdingRazor) {
        // draw razor onto right hand
        razorX = convertedRightHand.x-25;
        razorY = convertedRightHand.y-50;
        
        if (isCoordinateInStorage(razorX, razorY)) {
          // put the razor back into the storage
          holdingRazor = false; 
          razorX = razorStorageX;
          razorY = razorStorageY;
        }
        
        // collision detection between razor and mustache
        if (razorX > (mustacheX - (mustacheWidth/2)) && razorX < (mustacheX + (mustacheWidth/2)) && razorY > (mustacheY + (mustacheHeight/2)) && razorY < ( (mustacheY + mustacheY / 2) + 30)) {
          if ((!fadingOut) && mustacheVisible) {
            // shave off mustache
            startFadeOutMustache();
            lastTimeShaved = millis();
          }
        }
      } else {
        float handX = convertedRightHand.x;
        float handY = convertedRightHand.y;
        if (isCoordinateInStorage(handX, handY) ) {
          if (!holdingRazor) {
            holdingRazor = true;
          }
          else {
            holdingRazor = false;
          }
        }
      }
      
      // draw razor
      image(razor, razorX, razorY, razorWidth, razorHeight);
      
      // set mustache opacity
      if (mustacheVisible && !(fadingIn||fadingOut)) tint(255, 255);
      else tint(255, 255*mustacheTransparency);      

      // draw mustache
      if (mustacheVisible || fadingIn || fadingOut) image(mustache, mustacheX, mustacheY, mustacheWidth, mustacheHeight);
      tint(255, 255);
      
      // react to collision between razor and mustache
      if (fadingOut) doFadeOutMustache();
      else if (fadingIn) doFadeInMustache();
    }
  }
  
  // draw mirror
  imageMode(CORNER);
  image(mirrorImage, 0, 0);
}

// collision detection between razor and razor storage
boolean isCoordinateInStorage(float handX, float handY) {
  return (handX > razorStorageX && handX < razorStorageX + razorStorageWidth && handY > razorStorageY && handY < razorStorageY + razorStorageHeight);
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
