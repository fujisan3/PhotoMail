//
//  ViewController.m
//  PhotoMail
//
//  Created by fujisan3 on 2014/11/07.
//  Copyright (c) 2014年 mycompany. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate> {
    UIImagePickerController *c_picker;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 画像の取得元をカメラに設定
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // カメラが使えるかどうかチェックして、使える場合はカメラを初期化
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        c_picker = [[UIImagePickerController alloc] init];
        c_picker.sourceType = sourceType;
        c_picker.delegate = self;   // Delegate
    }
    
    [self showImagePicker];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark User Function
// 撮影画面の表示
- (void)showImagePicker {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:c_picker animated:YES completion:nil]; // 撮影画面を出す
    });
}

// メール送信
- (void)sendMail {
    
    // メール送信のための設定が完了している場合のみ実行される
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *m_picker = [[MFMailComposeViewController alloc] init];
        m_picker.mailComposeDelegate = self;
        
        [m_picker setSubject:@"アプリからの送信メールです"];                         // Subject

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString* emailTo = [userDefaults stringForKey: @"MailAddress"];
        [m_picker setToRecipients:[NSArray arrayWithObjects:emailTo, nil]];     // To
        
        NSString *emailBody = @"このメールはiPhoneアプリから送信されています";
        [m_picker setMessageBody:emailBody isHTML:NO];                          // Body
        
        CGFloat compressionQuality = 0.8;                                       // 添付画像 圧縮率0.8
        NSData *attachData = UIImageJPEGRepresentation(self.imageView.image, compressionQuality);
        [m_picker addAttachmentData:attachData mimeType:@"image/jpeg" fileName:@"photo.jpg"];
        
        [self presentViewController:m_picker animated:YES completion:nil];      // 送信画面表示
    }
}

#pragma mark Delegate Method(UIImagePickerControllerDelegate)
// 撮影後に実行される
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion: ^ {
        self.imageView.image = image;
        
        // アルバムに画像を保存
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        // そのままメール送信画面へ（今回やりたかったこと）
        [self sendMail];
    }];
}

#pragma mark Delegate Method(MFMailComposeViewControllerDelegate)
// メール送信後に実行される
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    // 送信後のエラーチェック
    NSString *mailError = nil;
    switch (result) {
        case MFMailComposeResultSent:
            mailError = @"メールの送信に成功しました";
            break;
        case MFMailComposeResultFailed:
            mailError = @"メールの送信に失敗しました";
            break;
        default:
            break;
    }
    if (mailError != nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:mailError delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    // 送信画面を消す
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark IBAction
- (IBAction)clickCameraButton:(id)sender {
    [self showImagePicker];
}

// Mailボタンクリック時の処理。未撮影時は撮影画面へ
- (IBAction)clickMailButton:(id)sender {

    if (self.imageView.image == nil) {
        // 未撮影の場合は警告後撮影画面へ
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"写真を撮影してください" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [self showImagePicker];
    } else {
        [self sendMail];
    }

}

@end
