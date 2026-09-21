import CoreGraphics
@main struct FitCheck {
 static func main() {
  for bounds in [CGRect(x:0,y:0,width:1710,height:1112), CGRect(x:0,y:0,width:1280,height:832), CGRect(x:0,y:0,width:1920,height:1080),CGRect(x:0,y:0,width:800,height:1200)] {
   for video in [CGSize(width:2560,height:1664),CGSize(width:2560,height:1440)] {
    let r = VideoFit.rect(video:video,inside:bounds)
    precondition(r.minX >= bounds.minX - 0.00001 && r.maxX <= bounds.maxX + 0.00001)
    precondition(r.minY >= bounds.minY - 0.00001 && r.maxY <= bounds.maxY + 0.00001)
    precondition(abs(r.width/r.height-video.width/video.height)<0.00001)
   }
  }
  let r=VideoFit.rect(video:CGSize(width:2560,height:1440),inside:CGRect(x:0,y:0,width:2560,height:1664))
  precondition(r == CGRect(x:0,y:112,width:2560,height:1440))
  print("PASS: full frame retained across 8 display/video combinations; 112px top/bottom bars")
 }
}
