import processing.video.*;                            // KCR 4x2 screens for Ryerson ~ January 2017 Dan Ribaudo
int tile_w = 1920 / 4;                                // CONTROLS:
int tile_h = 540 / 2;                                 // o: slower, longer intervals between slide changes
Screen[] tvs = new Screen[11];                        // p: faster, shorter intervals between slide changes
                                                      // k: slower, longer crossfades
SuperScreen ss = new SuperScreen();                   // l: faster, shorter crossfades
CategoryAlbum[] cats = new CategoryAlbum[8];          // 
CategoryAlbum ca;                                     // m: mute / unmute toggle audio
TextAlbum textAlbum;                                  //
OsdMaster osdMaster;                                  // q: no movie, 8 stills
int lastMillis = 100;                                 // w: big movie left half
int serveLastMillis = -1;                             // e: big movie middle half
int textIncrement = 1;                                // r: big movie right half
int textScreenSpacing = 2;                            //
int textScreenSkipCount = 0;                          // a: small movie, 7 stills
boolean db = false;                                   // s: small movie, big stills left
long slidePeriodMs = 5000;                            // d: small movie, big stills middle
long crossfadeDurationMs = 2000;                      // f: small movie, big stills right
float fadeRate = 1 / crossfadeDurationMs;             // 
long osdTimeoutDurationMs = 3000;                     // t: texts on fewer screens
Movie myMovie;                                        // y: texts on more screens
PFont f, f2;                                          //
float fadeIncrement = 0.08;                           // 
                                                      // 


class SuperScreen {                            
  int catPoint = 0;                           // next category to grab from
  int tvPoint = 1;                            // next tv to push to
  int config = 0;    // corresponds to q-w-e-r-a-s-d-f in controls
  boolean muted = false;
  String path;
  PImage img = createImage(1920, 1080, RGB);
  public SuperScreen() {
    if(db)println("I am a screen of multiple screens.");
  }
  void serve() {
    // get
    CategoryAlbum ca = cats[catPoint];
    path = ca.newestPath();
    img = loadImage(path);  
    // set
    if(db)println("..into screen #" + tvPoint);
    Screen s = tvs[tvPoint];
    s.summon(img,millis());
    // advance pointers
    catPoint++; if(catPoint>7) catPoint = 0;
    switch(config) {                 // [0][1][2][3]
      case 00: tvPoint++;            // [4][5][6][7]          
              if(tvPoint>7) tvPoint = 0;
      break;
      case 11: switch(tvPoint) {     // [m][m][2][3]
        case 2: tvPoint = 3; break;  // [m][m][6][7]
        case 3: tvPoint = 6; break;
        case 6: tvPoint = 7; break;
        default :tvPoint = 2; break;
      }                
      break;
      case 22: switch(tvPoint) {     // [0][m][m][3]
        case 0: tvPoint = 3; break;  // [4][m][m][7]
        case 3: tvPoint = 4; break;
        case 4: tvPoint = 7; break;
        default :tvPoint = 0; break;
      }                
      break;
      case 33: switch(tvPoint) {     // [0][1][m][m]
        case 0: tvPoint = 1; break;  // [4][5][m][m]
        case 1: tvPoint = 4; break; 
        case 4: tvPoint = 5; break;
        default :tvPoint = 0; break;
      }
      break;
      case 44: switch(tvPoint) {     // [0][m][2][3]
        case 0: tvPoint = 2; break;  // [4][5][6][7]
        case 2: tvPoint = 3; break;
        case 3: tvPoint = 4; break;
        case 4: tvPoint = 5; break;
        case 5: tvPoint = 6; break;
        case 6: tvPoint = 7; break;
        default: tvPoint = 0; break;
      }
      break;
      case 55: switch(tvPoint) {     // [8][8][m][3]
        case 8: tvPoint = 3; break;  // [8][8][6][7]
        case 3: tvPoint = 6; break;
        case 6: tvPoint = 7; break;
        default: tvPoint = 8; break;
      }
      break;
      case 66: switch(tvPoint) {     // [m][9][9][3]
        case 3: tvPoint = 4; break;  // [4][9][9][7]
        case 4: tvPoint = 7; break;
        case 9: tvPoint = 3; break;
        default: tvPoint = 9; break;
      }
      break;
      case 77: switch(tvPoint) {     // [0][m][A][A]
        case 0: tvPoint = 4; break;  // [4][5][A][A]
        case 4: tvPoint = 5; break;
        case 10: tvPoint = 0; break;
        default: tvPoint = 10; break;
      }
      break;

    }
  }
  
  void goConfig(int _c) {
    if(db)println("they out here sayin go to config #" + _c);
    config = _c;
    allDraw();
  }
  void mute() {
    myMovie.volume(0);
    muted = true;
    if(db)println("mute");
  }
  void unmute() {
    myMovie.volume(1);
    muted = false;
    if(db)println("unmute");
  }
}
    
class Screen { 
  int x;
  int y;
  boolean doubleSized;
  int id;
  PImage imgFrom = createImage(1920,1080,RGB);  
  PImage imgTo = createImage(1920,1080,RGB);
  float fadeRatio = 0.0;
  float fadeRemain = 0.0;
  int fadeStartMillis;
  String txt = new String();
  boolean txtVisible = true;
  boolean txtDrawn = false;
  float fadeTxtRatio = 0.0;
  PImage composite = createImage(1920,1080,RGB);
  int dMult = 1;
  
  public Screen(int _id, int _x, int _y, boolean _d) {
    x = _x;    y = _y;    id = _id;   doubleSized = _d;
    if (doubleSized) dMult = 2;
  }
  void summon(PImage _img, int _t) {
    if(db)println("time to summon " + _t);
    imgTo = _img;
    txt = textAlbum.nextText(textIncrement);
    if(textScreenSkipCount < textScreenSpacing) {
      txtVisible = false;
      textScreenSkipCount += 1;
    }
    else {
      txtVisible = true;
      textScreenSkipCount = 0;
    }
    fadeStartMillis = _t;
    fadeRatio = 0.01;
    txtDrawn = false;
  }
  void rendr(int _t) {  // rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
    noTint();
    if (fadeRatio > 0.0) {
      image(imgFrom, x, y, tile_w * dMult, tile_h * dMult);
      tint(255, fadeRatio * 255);
      image(imgTo, x, y, tile_w * dMult, tile_h * dMult);
      fadeRatio += fadeIncrement;
      if (fadeRatio > 1.0) {
        fadeRatio = 0.0; 
        imgFrom = imgTo;
      }
    }
    else {
      if (txtVisible && !(txtDrawn)) {
        textFont(f);
        textAlign(CENTER, CENTER);
        text(txt, x, y + tile_h / 2, tile_w, tile_h / 2);
        txtDrawn = true;
        
      }
    }
  }    
    void rendr() {   // no param means force
      noTint();
      image(imgFrom, x, y, tile_w * dMult, tile_h * dMult);
      tint(255, fadeRatio * 255);
      image(imgTo, x, y, tile_w * dMult, tile_h * dMult);
      fadeRatio += fadeIncrement;
      if (fadeRatio > 1.0) {
        fadeRatio = 0.0; 
        imgFrom = imgTo;
      }
    }
}


class CategoryAlbum { // a photo album is pure memories, man [][][][][][][][][][][][][][][][][][][][][][]\\
  // Contains category-specific image filepaths,
  // an ordering of them,
  // and a pointer to position within that order
  String categoryName;
  Table data = loadTable("KCR_master_list.csv", "header");
  StringList imgPaths;
  StringList sL;
  int[] indexQueue = new int[] {0};
  int qPoint = 0;  
  int qPointsTo;
  String qPointsToPath;
  String filepathPrefix = "/Volumes/KCR/KCR_Harvard_export_April15/";
  int prefixLength = filepathPrefix.length();
  
  public CategoryAlbum(String _categoryName) {
    if(db)print("starting category: ", _categoryName);
    categoryName = _categoryName;

    // imgPaths is a static list of filenames
    imgPaths = new StringList();

    // read the data table for images of category, add them to imgPaths
    for(TableRow row : data.rows()) {
      if(row.getInt("boolean") == 1) {
        if(row.getString("topographic_category").matches(_categoryName)) { 
          imgPaths.append("kcr-img/" + row.getString("filepath").substring(prefixLength));
        }
      }
    }

    // indexQueue is an ordered set of indices to imgPaths
    if(db)println("... total: ", imgPaths.size());

    int size = imgPaths.size();
    for(int i = 0; i<size; i++) {
      indexQueue = append(indexQueue, i);
    }
  }
  
  String newestPath() { 
    
    // advance the pointer and return a filepath for the next image
    qPoint++; if(qPoint>=indexQueue.length)qPoint = 0;
    qPointsTo = indexQueue[qPoint];
    qPointsToPath = imgPaths.get(qPointsTo);
    if(db)println("qPoint:",qPoint,"to:",qPointsTo,"path:",qPointsToPath);
    if(db)println("len:",indexQueue.length,"for category ",categoryName);
    
    
    return qPointsToPath;
    
    // here the last image should be shuffled
  }
  
}

class TextAlbum {  // repo for the verbage  ~ T ~ t ~ T ~ t ~ T ~ t ~ T ~ t ~ T ~ t ~ T ~ t ~ T ~ t ~ T ~ t
  ArrayList<String> blurbs;
  int pointer = 0;
  int count;
  public TextAlbum() {
    blurbs = new ArrayList<String>();
    Table data = loadTable("KCR_text.csv", "header");
    if(db)println(data.getRowCount() + " total rows in text table.");
    for(TableRow row : data.rows()) {
      String s = row.getString("sentences");
      if (s != "") blurbs.add(s);
    }
    count = blurbs.size();
  }
  String nextText(int _n){
    pointer += _n; 
    if (pointer >= count) pointer = 0;
    return blurbs.get(pointer);
  }
  
}

class OsdMaster {  // key-responsive message overlays...........................................................
  String message;
  boolean onscreen = false;
  long onscreenTimerMs = osdTimeoutDurationMs;
  long fromTime;
  public OsdMaster() {
  }
  void userSaid(char _k) {
    if(db)println("> user presses "+_k);
    switch(_k) {
      case 'o': 
                slidePeriodMs += 1000; 
                message = "o: Slide Change Interval " + slidePeriodMs/1000 + " sec";
                osdSay(message); break;
      case 'p': 
                slidePeriodMs -= 1000;
                if(slidePeriodMs<1000)slidePeriodMs = 1000;
                message = ("p: Slide Change Interval " + slidePeriodMs/1000 + " sec");
                osdSay(message); break;
      case 'k': 
                crossfadeDurationMs += 200;
                fadeIncrement *= 0.6;
                message = "k: Crossfade longer";
                osdSay(message); break;
      case 'l':
                crossfadeDurationMs -= 200;
                if(crossfadeDurationMs<200) crossfadeDurationMs = 200;
                fadeIncrement *= 1.6;
                message = "l: Crossfade shorter";
                osdSay(message); break;
      
      case 'm': if (ss.muted) ss.unmute(); else ss.mute(); break;
      case 'q': ss.goConfig(00); break;
      case 'w': ss.goConfig(11); break;
      case 'e': ss.goConfig(22); break;
      case 'r': ss.goConfig(33); break;
      case 'a': ss.goConfig(44); break;
      case 's': ss.goConfig(55); break;
      case 'd': ss.goConfig(66); break;
      case 'f': ss.goConfig(77); break;
      case 't': 
                textScreenSpacing += 1;
                message = "t: Text every " + (textScreenSpacing + 1) + " screens";
                osdSay(message); break;
      case 'y':
                textScreenSpacing -= 1;
                if (textScreenSpacing < 0) textScreenSpacing = 0;
                message = "y: Text every " + (textScreenSpacing + 1) + " screens";
                osdSay(message); break;
    }
  }
  void osdSay(String _s) {
    onscreen = false;
    int now = millis();
    fill(0,200); rect(0,(height *0.4), width, (height * 0.2));
    fill(255);
    onscreen = true;
    fromTime = millis();
    message = _s;
    textFont(f2);
    textAlign(CENTER, CENTER);
    text(message, width/2, height/2);
    if(db)println("OSD says " + message);
  }
  void runTimer(int _t) {
    text(message, width/2, height/2);
    if(db)print("OSD is onscreen for ");
    onscreenTimerMs = osdTimeoutDurationMs - (_t - fromTime);
    if(db)println(onscreenTimerMs);
    if (onscreenTimerMs <= 0) {
      onscreen = false;
      int now = millis();
      allDraw();
    }
  }
}

void setup() { // sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
  
  size(1920,540);
  db = true; // print the debuggables
   
  osdMaster = new OsdMaster();
  f = createFont("Verdana", 12);
  f2 = createFont("Monospaced", 32);

  myMovie = new Movie(this,"kcr.mp4");
  myMovie.loop();
  
  // initialize the albums
  
  cats[0] = new CategoryAlbum("Vista");
  cats[1] = new CategoryAlbum("Play");
  cats[2] = new CategoryAlbum("Informal housing");
  cats[3] = new CategoryAlbum("Railway infrastructure");
  cats[4] = new CategoryAlbum("Crossing");
  cats[5] = new CategoryAlbum("Market");
  cats[6] = new CategoryAlbum("Station");
  cats[7] = new CategoryAlbum("Tracks");
  
  textAlbum = new TextAlbum();
  
  // set the screen positions
  tvs[0] = new Screen(11, 0, 0, false);
  tvs[1] = new Screen(12, floor(width * 0.25), 0, false);
  tvs[2] = new Screen(13, floor(width * 0.50), 0, false); 
  tvs[3] = new Screen(14, floor(width * 0.75), 0, false);
  tvs[4] = new Screen(21, 0, floor(height / 2), false);
  tvs[5] = new Screen(22, floor(width * 0.25), floor(height / 2), false);
  tvs[6] = new Screen(23, floor(width * 0.50), floor(height / 2), false); 
  tvs[7] = new Screen(24, floor(width * 0.75), floor(height / 2), false); 
  tvs[8] = new Screen(1111, 0, 0, true);
  tvs[9] = new Screen(2222, floor(width * 0.25), 0, true);
  tvs[10] = new Screen(3333, floor(height / 2), 0, true);
  

  osdMaster.osdSay("---");
}

void draw() { // ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

  int now = millis();
  if ((now - lastMillis) > 42) { // 24 FPS ambition
    allDraw(now);
    lastMillis = now;
  }

  if((millis() - serveLastMillis) > slidePeriodMs) {
    serveLastMillis = millis();
    if(db)println("New Slide,", '\t', millis(),"ms into runtime");
    ss.serve();
  }
  
  if (osdMaster.onscreen) osdMaster.runTimer(millis());  
}

void keyPressed() {
  osdMaster.userSaid(key);
}

void movieEvent(Movie m) 
{
  m.read();
}

void allDraw(int _t) {
  int now = _t;
  switch (ss.config) {

    case 00://  [0][1][2][3]
            //  [4][5][6][7]
            tvs[0].rendr(now);    tvs[1].rendr(now);    tvs[2].rendr(now);    tvs[3].rendr(now);
            tvs[4].rendr(now);    tvs[5].rendr(now);    tvs[6].rendr(now);    tvs[7].rendr(now); 
            break;
    case 11://  [\][/][2][3]
            //  [/][\][6][7]
            tvs[2].rendr(now);    tvs[3].rendr(now);
            tvs[6].rendr(now);    tvs[7].rendr(now);
            image(myMovie, 0, 0, tile_w * 2, tile_h * 2);
            break;
    case 22://  [0][\][/][3]
            //  [4][/][\][7]
            tvs[0].rendr(now);    tvs[3].rendr(now);
            tvs[4].rendr(now);    tvs[7].rendr(now);
            image(myMovie, (width * 0.25), 0, tile_w * 2, tile_h * 2);
            break;
    case 33://  [0][1][\][/]
            //  [4][5][/][\]
            tvs[0].rendr(now);    tvs[1].rendr(now);   
            tvs[4].rendr(now);    tvs[5].rendr(now);
            image(myMovie, (width / 2), 0, tile_w * 2, tile_h * 2);
            break;
    case 44://  [0][m][2][3]
            //  [4][5][6][7]
            tvs[0].rendr(now);                          tvs[2].rendr(now);    tvs[3].rendr(now);
            tvs[4].rendr(now);    tvs[5].rendr(now);    tvs[6].rendr(now);    tvs[7].rendr(now); 
            image(myMovie, (width * 0.25), 0, tile_w, tile_h);
            break;
    case 55://  [8][8][m][3]
            //  [8][8][6][7]
            tvs[3].rendr(now);
            tvs[6].rendr(now);    tvs[7].rendr(now);    tvs[8].rendr(now);
            image(myMovie, (width / 2), 0, tile_w, tile_h);
            break;
    case 66://  [m][9][9][3]
            //  [4][9][9][7]
                 tvs[3].rendr(now);
            tvs[4].rendr(now);    tvs[7].rendr(now);    tvs[9].rendr(now);
            image(myMovie, 0, 0, tile_w, tile_h);
            break;
    case 77://  [0][m][A][A]
            //  [4][5][A][A]
            tvs[0].rendr(now);        
            tvs[4].rendr(now);    tvs[5].rendr(now);    tvs[10].rendr(now);
            image(myMovie, (width * 0.25), 0, tile_w, tile_h);
            break;
  } 
}

void allDraw() { // forcey version
  switch (ss.config) {

    case 00://  [0][1][2][3]
            //  [4][5][6][7]
            tvs[0].rendr();    tvs[1].rendr();    tvs[2].rendr();    tvs[3].rendr();
            tvs[4].rendr();    tvs[5].rendr();    tvs[6].rendr();    tvs[7].rendr(); 
            break;
    case 11://  [\][/][2][3]
            //  [/][\][6][7]
            tvs[2].rendr();    tvs[3].rendr();
            tvs[6].rendr();    tvs[7].rendr();
            image(myMovie, 0, 0, tile_w * 2, tile_h * 2);
            break;
    case 22://  [0][\][/][3]
            //  [4][/][\][7]
            tvs[0].rendr();    tvs[3].rendr();
            tvs[4].rendr();    tvs[7].rendr();
            image(myMovie, (width * 0.25), 0, tile_w * 2, tile_h * 2);
            break;
    case 33://  [0][1][\][/]
            //  [4][5][/][\]
            tvs[0].rendr();    tvs[1].rendr();   
            tvs[4].rendr();    tvs[5].rendr();
            image(myMovie, (width / 2), 0, tile_w * 2, tile_h * 2);
            break;
    case 44://  [0][m][2][3]
            //  [4][5][6][7]
            tvs[0].rendr();                          tvs[2].rendr();    tvs[3].rendr();
            tvs[4].rendr();    tvs[5].rendr();    tvs[6].rendr();    tvs[7].rendr(); 
            image(myMovie, (width * 0.25), 0, tile_w, tile_h);
            break;
    case 55://  [8][8][m][3]
            //  [8][8][6][7]
                tvs[3].rendr();
            tvs[6].rendr();    tvs[7].rendr();    tvs[8].rendr();
            image(myMovie, (width / 2), 0, tile_w, tile_h);
            break;
    case 66://  [m][9][9][3]
            //  [4][9][9][7]
                tvs[3].rendr();
            tvs[4].rendr();    tvs[7].rendr();    tvs[9].rendr();
            image(myMovie, 0, 0, tile_w, tile_h);
            break;
    case 77://  [0][m][A][A]
            //  [4][5][A][A]
            tvs[0].rendr();     
            tvs[4].rendr();    tvs[5].rendr();    tvs[10].rendr();
            image(myMovie, (width * 0.25), 0, tile_w, tile_h);
            break;
  } 
}
