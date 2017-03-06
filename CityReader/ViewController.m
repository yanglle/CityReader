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

@interface ViewController ()
//客户端socket

@property (weak, nonatomic) IBOutlet UITextView *messageTF;
@property (nonatomic) GCDAsyncSocket *clinetSocket;
@property (weak, nonatomic) IBOutlet UITextField *channelTF;
@property (nonatomic, retain) UIImagePickerController *imagePicker;
@property(nonatomic, strong) NSData *fileData;

@end
BOOL *onPhoto=NO;
BOOL *isConnected=NO;
@implementation ViewController
    NSString *IP =@"192.168.1.110";
//  NSString *IP =@"192.168.31.249";

    NSString *upLoadImg_url =@"/city/imgSave.php";
    NSString *channel;
    int port =3344;
- (void)viewDidLoad {
    [super viewDidLoad];
    //连接服务器
    
    _clinetSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    

    
    
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

    [self showMessageWithStr:@"链接成功"];
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
    [self.imagePicker takePicture];
    [self.clinetSocket readDataWithTimeout:-1 tag:0];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

//开始连接
- (IBAction)connectAction:(id)sender {
    //2、连接服务器
    NSLog(@"连接服务器");
    NSError *error = nil;
    if (isConnected) {
        [self showMessageWithStr:@"已成功连接 "];

    }
    [_clinetSocket connectToHost:IP onPort:port withTimeout:-1 error:&error];
    if (error) {
        NSLog(@"错误：%@",error);
    }
    
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
        channel=_channelTF.text;
        [self uploadImage:image withChannel:channel];
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

- (void)uploadImage:(UIImage *)photo withChannel:(NSString *) channel
{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    /*方式一：使用NSData数据流传图片*/
    NSDictionary *param = @{@"channel":channel};
    NSString *fileName = [[NSString alloc]initWithFormat:@"%@%@", channel,@".jpg" ];
    NSString *imageURl =[[NSString alloc]initWithFormat:@"%@%@%@",@"http://",IP,upLoadImg_url ];
    //imageURl =@"http://www.lswdz.cn/zsny/dp/imgSave.php";
    //url 转码
    //imageURl = [imageURl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSLog(@"channel:%@",channel);
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes =[NSSet setWithObject:@"text/html"];

    NSLog(@"上传图片接口：%@",imageURl);
    [manager POST:imageURl parameters:param constructingBodyWithBlock:^(id formData) {
        //UIImageJPEGRepresentation 第二个参数是图片质量压缩系数 如果数据太大，可以考虑改成0.8
        NSData *data = UIImageJPEGRepresentation(photo, 0.6);
        
        NSLog(@"%lu KB",[data length]/1024);
        if(data!=nil){
            [formData appendPartWithFileData:data name:@"imgData" fileName:@"_Moment.jpg" mimeType:@"image/jpg"];
            NSLog(@"开始上传图像");
        }
        
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"上传图像成功：%@", responseString);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"上传图像失败：%@",error);
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


