//
//  ViewController.m
//  CityReader
//
//  Created by yanglle on 17/2/17.
//  Copyright © 2017年 yanglle. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "AFHTTPSessionManager.h"
#import "GCDAsyncSocket.h"
#import "YYKit.h"

@interface ViewController ()
//客户端socket
@property (weak, nonatomic) IBOutlet UITextField *ipTF;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;

@property (weak, nonatomic) IBOutlet UIButton *subBtn;
@property (weak, nonatomic) IBOutlet UILabel *channelLab;
@property (weak, nonatomic) IBOutlet UITextView *messageTF;
@property (nonatomic) GCDAsyncSocket *clinetSocket;

@property (nonatomic, retain) UIImagePickerController *imagePicker;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property(nonatomic, strong) NSData *fileData;

@end
BOOL *onPhoto=0;
BOOL *isConnected;
NSString *IP;
int i ;
@implementation ViewController
    NSString *upLoadImg_url =@":50099/upload.html";
    NSString *channel;
    int port =3344;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAPP];
    
}
-(void)initAPP{
    isConnected=0;
    i =arc4random() % 50;
    [self showMessageWithStr:@"请确保和服务端电脑在同一网络"];
    //连接服务器
    _channelLab.clipsToBounds=YES;
    _channelLab.layer.cornerRadius=75;
    _startBtn.clipsToBounds=YES;
    _startBtn.layer.cornerRadius=75;
    _channelLab.text= [[NSString alloc] initWithFormat:@"%d",i];
    _clinetSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}
- (IBAction)subClick:(id)sender {
    if (i>1) {
        i--;
      _channelLab.text= [[NSString alloc] initWithFormat:@"%d",i];
    }
    
}
- (IBAction)addClick:(id)sender {
    if(i<66){
      i++;
    _channelLab.text= [[NSString alloc] initWithFormat:@"%d",i];
    }
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (err) {
        NSLog(@"%@",err);
    }
}
#pragma mark - GCDAsynSocket Delegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSData *welcome =[@"hello sever!" dataUsingEncoding:NSUTF8StringEncoding];
    [_clinetSocket writeData:welcome withTimeout:1000 tag:1];
    [self showMessageWithStr:@"已成功连接"];
    isConnected = 1;
    [_startBtn setBackgroundColor:[UIColor orangeColor]];
    _startBtn.titleLabel.text=@"断开";

    [self showMessageWithStr:[NSString stringWithFormat:@"服务器IP ： %@", host]];
    [self.clinetSocket readDataWithTimeout:-1 tag:0];
}

//收到消息
//  ready   111
//  pause  333
//  photo  666
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    int ivalue = [text intValue];
    [self showMessageWithStr:text];
    switch (ivalue) {
        case 111:
            [self ready];
            break;
        case 333:
            [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
        case 666:
            [self.imagePicker takePicture];
        default:
            break;
    }
    [self.clinetSocket readDataWithTimeout:-1 tag:0];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

//开始连接
- (IBAction)connectAction:(id)sender {
    //2、连接服务器
   IP = _ipTF.text;
    NSError *error = nil;
    if (isConnected) {
        [_clinetSocket disconnect];
        isConnected=0;
        _startBtn.titleLabel.text=@"连接";
        [_startBtn setBackgroundColor:[UIColor lightGrayColor]];
        [self showMessageWithStr:@"已断开连接"];
    }else
       // if([self isIP:IP]){
        [_clinetSocket connectToHost:IP onPort:port withTimeout:-1 error:&error];
       // }else{
       //     [self showMessageWithStr:@"ip格式错误，请检查"];
       // }
   
}
- (void)ready{

    int mediaType=0;
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.delegate = self;
    _imagePicker.allowsEditing = NO;
    
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePicker.cameraFlashMode =UIImagePickerControllerCameraFlashModeOff;
    _imagePicker.cameraViewTransform = CGAffineTransformMakeScale(1.7, 1.7);
    _imagePicker.showsCameraControls  =NO;
    switch (mediaType) {
        case 0://照相机
        {
            [self presentViewController:_imagePicker animated:YES completion:nil];
        }
            break;
            
        case 1://录像机 有BUG
        {
            _imagePicker.mediaTypes = @[(NSString *)kUTTypeVideo];
            _imagePicker.videoMaximumDuration =5;
            _imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            [self presentViewController:_imagePicker animated:YES completion:nil];
        }
            break;
        default:
            break;
    }

}

//发送消息
- (IBAction)sendMessageAction:(id)sender {
    NSData *data = [self.messageTF.text dataUsingEncoding:NSUTF8StringEncoding];
    //withTimeout -1 :无穷大
    //tag： 消息标记
    [self.clinetSocket writeData:data withTimeout:-1 tag:0];
}

//接收消息
- (IBAction)receiveMessageAction:(id)sender {
    [self.clinetSocket readDataWithTimeout:11 tag:0];
}

- (void)showMessageWithStr:(NSString *)str{
    self.messageTF.text = [self.messageTF.text stringByAppendingFormat:@"%@\n", str];
}
- (BOOL)isIP:(NSString *)ipString{
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"((2[0-4]\d|25[0-5]|[01]?\d\d?)\.){3}(2[0-4]\d|25[0-5]|[01]?\d\d?)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:ipString options:0 range:NSMakeRange(0, [ipString length])];
    return result;
}
-(void)sendImg:(UIImage *)img withChannel:(NSString *)channel{
    NSData *data = UIImageJPEGRepresentation(img, 0.05);
    channel =[channel stringByAppendingString:@".jpg"];
    NSString *imageURl =[[NSString alloc]initWithFormat:@"%@%@%@",@"http://",IP,upLoadImg_url ];
    //NSLog(@"%lu KB  %lld",[data length]/1024,[channel longLongValue]);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                         
                                                         @"text/html",
                                                         
                                                         @"image/jpeg",
                                                         
                                                         @"image/png",
                                                         
                                                         @"application/octet-stream",
                                                         
                                                         @"text/json",
                                                         
                                                         nil];
    
    manager.requestSerializer= [AFHTTPRequestSerializer serializer];
    
    manager.responseSerializer= [AFHTTPResponseSerializer serializer];
    [manager POST:imageURl parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFileData:data name:@"file" fileName:channel mimeType:@"image/jpg"];
      
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"上传图像成功：%@", responseString);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           NSLog(@"上传图像失败：%@",error);
    }];

}
#pragma mark-
#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:(NSString *)kUTTypeImage]) {
        //图片保存和展示
        UIImage *image;
        if (picker.allowsEditing) {
            image = [info objectForKey:UIImagePickerControllerEditedImage]; //允许编辑，获取编辑过的图片
        }
        else{
            image = [info objectForKey:UIImagePickerControllerOriginalImage]; //不允许编辑，获取原图片
        }
        channel=_channelLab.text;
         [self sendImg:image withChannel:channel];
         //[self uploadImage:image withChannel:channel];
        
        //UIImageWriteToSavedPhotosAlbum(image,nil,nil, nil);
    }
    else if([type isEqualToString:(NSString *)kUTTypeVideo]){
        //视频保存后 播放视频
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *urlPath = [url path];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlPath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(urlPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    }
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    //    [picker dismissModalViewControllerAnimated:YES];
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


