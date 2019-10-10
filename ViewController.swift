//
//  ViewController.swift
//  MemeMe
//
//  Created by Varosyan, Anna on 07.05.19.
//  Copyright © 2019 Varosyan, Anna. All rights reserved.
//

import UIKit

struct Meme {
    var topText: String!
    var bottomText: String!
    var originalImage: UIImage?
    var memedImage: UIImage?
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: image view and text boxes
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    
    // MARK: toolbar buttons
    @IBOutlet weak var albumPickerButton: UIBarButtonItem!
    @IBOutlet weak var cameraPickerButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    @IBOutlet weak var topToolbar: UIToolbar!
    @IBOutlet weak var bottomToolbar: UIToolbar!
   
    // MARK: Definitions
    let topTextFieldDefaultText = "TOP"
    let bottomTextFieldDefaultText = "BOTTOM"
    
    let textFieldDelegate = TextFieldDelegate()
    
    var meme = Meme()
   
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth: -5
    ]
    
    // MARK: View actions
    override func viewDidLoad() {
        super.viewDidLoad();
        // check if camera is available
        cameraPickerButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        //setup text fields
        initTextField(topTextField, text: topTextFieldDefaultText);
        initTextField(bottomTextField, text: bottomTextFieldDefaultText);
    }
    
    // prepare view to receive keyboard notifications
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }

    // MARK: IBActions - toolbar buttons
    @IBAction func sharButtonPressed(_ sender: UIBarButtonItem) {
        let memedImage = generateMemedImage();
        let activityViewController = UIActivityViewController(activityItems: [ memedImage ], applicationActivities: nil);
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
            // Create the meme
            if completed {
                self.saveMeme()
            }
            
        }
        self.present(activityViewController, animated: true, completion: nil)
    }

    @IBAction func cancelOperations(_ sender: Any) {
        resetTextField(topTextField, text: topTextFieldDefaultText);
        resetTextField(bottomTextField, text: bottomTextFieldDefaultText);
        imageView.image = nil
        shareButton.isEnabled = false
        clearMeme();
        
    }

    @IBAction func loadAlbumToPickAnImage(_ sender: Any) {
        presentImagePickerWith(sourceType: .photoLibrary)
    }
    
    @IBAction func loadCameraToPickAnImage(_ sender: Any) {
        presentImagePickerWith(sourceType: .camera)
    }
    
    // Displays ImagePickerController for the specified source type
    func presentImagePickerWith(sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: IBActions - text fields
    @IBAction func topTextFieldDidBeginEditing(_ sender: UITextField) {
        cleanTextField(topTextField)
    }

    @IBAction func topTextFieldEditingDidEnd(_ sender: Any) {
        if (topTextField.text == "") {
            resetTextField(topTextField, text: topTextFieldDefaultText)
        }
    }
    
    @IBAction func bottomTextFieldDidBeginEditing(_ sender: UITextField) {
        cleanTextField(bottomTextField)
    }
    
    @IBAction func bottomTextFieldEditingDidEnd(_ sender: Any) {
        if (bottomTextField.text == "") {
            resetTextField(bottomTextField, text: bottomTextFieldDefaultText)
        }
    }
    
    // MARK: KEYBOARD controlling functions
    func subscribeToKeyboardNotifications() {
      NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
 
      NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if view.frame.origin.y == 0 && bottomTextField.isEditing {
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        if view.frame.origin.y <= 0 && bottomTextField.isEditing {
            view.frame.origin.y += getKeyboardHeight(notification)
        }
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    // MARK: DELEGATEs - Camera/Album
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info [UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
        }
        dismiss(animated: true, completion: nil)
        shareButton.isEnabled = true

    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Meme functions
    func generateMemedImage() -> UIImage {
        // hide toolbars
        hideToolbars(true)
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        // show toolbars
        hideToolbars(false)
        return memedImage
    }
    
    func hideToolbars(_ hide: Bool){
        bottomToolbar.isHidden = hide
        topToolbar.isHidden = hide
    }
    
    func saveMeme() {
        // Create the meme
        meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imageView.image!, memedImage: generateMemedImage())
    }

    func clearMeme() {
        // Clear the meme
        meme.bottomText = ""
        meme.topText = ""
        meme.originalImage = nil
        meme.memedImage = nil
    }
    
    // MARK: Text field manipulation
    func resetTextField(_ textField: UITextField, text:String = "" ) {
        textField.text = text
        textField.tag = 1
    }
    
    func initTextField(_ textField: UITextField, text: String) {
        textField.backgroundColor = UIColor.clear
        textField.defaultTextAttributes = memeTextAttributes
        textField.delegate = textFieldDelegate
        textField.textAlignment = NSTextAlignment.center
        textField.tag = 1
        textField.text = text
    }
    
    func cleanTextField(_ textField: UITextField) {
        if textField.tag == 1 {
            textField.text = ""
            textField.tag = 0
        } 
    }
}
