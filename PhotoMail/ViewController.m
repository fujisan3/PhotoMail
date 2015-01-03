//
//  ViewController.m
//  PhotoMail
//
//  Created by Shingo Fujiwara on 2014/11/07. - 2015/1/4 upload to Github
//  Copyright (c) 2014年 mycompany. All rights reserved.
//

// ヘッダファイルも読み込んでいるので、.hに書いた内容も使える
#import "ViewController.h"

// デリゲートの指定を追加。UIImagePickerControllerDelegateは、UINavigationControllerDelegateの
// サブクラスなので両方の指定が必要らしい
// MFMailComposeViewControllerDelegate を使うには、MessageUIフレームワークが必要
@interface ViewController ()
    <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate>

// プログラムからイメージビューにアクセスするために必要
// コードエディタの行の左側に◯があり、それをクリックすると連携先コントロールが分かる
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

// プロパティ宣言。このプログラムでは外部からは使っていないが、複数の管数から使われているのでここで書いている？
@property UIImagePickerController *c_picker;

@end

// implementation-end 間に記述
@implementation ViewController


//-------------------------------
//  Single View Default Method
//-------------------------------

// ビューが読み込み終わったら実行される
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // アプリ起動時にカメラを表示する(初回のみ)
    //   => viewDidAppearでやると他のモーダル画面が出せなくなったのでやめた
    [self createImagePicker];
    [self showImagePicker];
}

// メモリ不足になったら実行される（メモリ開放するなど）
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//-------------------------------
//  Original Code
//-------------------------------

// カメラ設定。一度だけしか動かないからviewDidLoadに書いてもいいと思う
// ここでc_pickerを宣言してしまうと、showImagePickerで使えないので@propertyに書いている
- (void)createImagePicker {
    // データ取得元（source）をカメラに設定
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // カメラが使えるかどうかチェックして、使える場合はカメラを初期化（使用準備）
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        // カメラ初期化
        self.c_picker = [[UIImagePickerController alloc] init];
        // 取得元＝カメラ
        self.c_picker.sourceType = sourceType;
        // イベントハンドラの設定
        self.c_picker.delegate = self;
    }
}

// カメラ表示。Cameraボタンから起動した場合はカメラの設定は不要なので、画面表示のみのロジックとして分離
// dispatch_asyncは非同期呼び出し ＾｛はコードブロック
- (void)showImagePicker {
    // カメラ表示
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:self.c_picker animated:YES completion:nil];
    });
}

// メール送信のための関数
// m_pickerがここで宣言しているのは、この関数の中だけで使っているからここに書いていてもいい
- (void)sendMail {
    // メール送信のための設定が完了している場合のみ実行される
    if ([MFMailComposeViewController canSendMail]) {
        
        // メール送付準備
        MFMailComposeViewController *m_picker = [[MFMailComposeViewController alloc] init];
        m_picker.mailComposeDelegate = self; // メール送信後の処理を書くため
                                             // デリゲート宣言、デリゲート関数そのものの記述要
        
        // メールの件名
        [m_picker setSubject:@"アプリからの送信メールです"];
        
        // メールの宛先
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString* emailTo = [userDefaults stringForKey: @"MailAddress"];
        [m_picker setToRecipients:[NSArray arrayWithObjects:emailTo, nil]];
        
        // メールの本文を設定
        NSString *emailBody = @"このメールはiPhoneアプリから送信されています";
        [m_picker setMessageBody:emailBody isHTML:NO];
        
        // 撮影した写真を添付画像とする --------------------
        CGFloat compressionQuality = 0.8; // 圧縮率0.8で圧縮する
        NSData *attachData = UIImageJPEGRepresentation(self.imageView.image, compressionQuality);
        [m_picker addAttachmentData:attachData mimeType:@"image/jpeg" fileName:@"photo.jpg"];
        
        // メール送信画面がアニメーション付きで表示される
        // 一旦処理はメール送信画面に移るのでメール送信そのもののコードは書かなくても良い
        // メール送信後の処理はデリゲートで処理（上記にてデリゲートを指定している）
        [self presentViewController:m_picker animated:YES completion:nil];
    }
}


//-------------------------------
//  UI event methods
//  画面コントロールと連携しているコードコードエディタの左側に◯が表示されている
//-------------------------------

// Cameraボタンクリック時処理。カメラ設定は完了しているので、撮影画面を表示するロジックのみ記述された関数をコール
- (IBAction)clickCameraButton:(id)sender {
    [self showImagePicker];
}

// Mailボタンクリック時処理。前回撮影写真を再度メールする場合に使用。撮影していない場合はエラーになるので回避
- (IBAction)clickMailButton:(id)sender {
    // 撮影してないとメール送信許しません！！！
    if (self.imageView.image == nil) {
        // 警告表示
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"写真を撮影してください" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        // 警告表示後、そのまま撮影画面へ
        [self showImagePicker];
    } else {
        // OKの場合はメール送信画面表示
        [self sendMail];
    }
}


//-------------------------------
//  Delegate methods
//-------------------------------

// カメラ撮影後にコールされる
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // レタッチ前の画像オブジェクト
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // カメラ画面を取り下げ（dismiss）、その後、前回撮影写真の表示とアルバムに画像を保存する
    [self dismissViewControllerAnimated:YES completion:^{
        // 撮影後画面の表示
        self.imageView.image = image;
        // アルバムに画像を保存
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        [self sendMail];
        
    }];
}

// メール送信後にコールされる
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
    
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
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
