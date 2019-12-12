//
//  EmojiArtViewController.swift
//  EmojiArt222
//
//  Created by AHMED GAMAL  on 12/7/19.
//  Copyright © 2019 AHMED GAMAL . All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    
    
    
    

   var emojiArtView = EmojiArtView()
    
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant =  scrollView.contentSize.width
    }
    
    
    
    
    
    
    
    var emojis = "😂🤪🦊🐥🦆🐝🦋🦚🌵🌴🍄🌼❤️🍎🌶🚙🚲🚘⚽️🏀🥊".map{String($0)}
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emojis.count
    }
    
    private var font : UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(50))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        if let emojiCell = cell as? EmojiCollectionViewCell{
            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font : font])
            emojiCell.label.attributedText = text
        }
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        session.localContext = collectionView
        return dragItems (at : indexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems (at : indexPath)
    }
    
    func dragItems (at indexpath : IndexPath) -> [UIDragItem]{
        if let atrributedString =  (emojiCollectionView.cellForItem(at: indexpath) as? EmojiCollectionViewCell)?.label.attributedText  {
        let dragitem = UIDragItem(itemProvider: NSItemProvider(object: atrributedString))
            dragitem.localObject = atrributedString
            return [dragitem]
    }
        else {return []}
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy   , intent: .insertAtDestinationIndexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item : 0 , section : 0)
        for item in  coordinator.items{
            if let sourceIndexPath = item.sourceIndexPath{
                if let attributedString = item.dragItem.localObject as? NSAttributedString{
                    
                    collectionView.performBatchUpdates({
                    emojis.remove(at: sourceIndexPath.item)
                    emojis.insert(attributedString.string, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                    })
                    
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            }
            else{
                let placeholderContext = coordinator.drop(item.dragItem,
                            to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath,
                                                                reuseIdentifier: "DropPlaceholderCell"))
                
                               item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                                   DispatchQueue.main.async {
                                       if let attributedString = provider as? NSAttributedString {
                                           placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                               self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                                           })
                                       } else {
                                           placeholderContext.deletePlaceholder()
                                       }
                                   }
                               }
                               
                           }
                       }
                   }
        
        
     
    var emojiArtBackgroundImage : UIImage?{
        get{
            return emojiArtView.backgroundImage
        }
        set {
            emojiArtView.backgroundImage = newValue
            let size = newValue?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant =  size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                           scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
                       }
        }
    }
    
    
    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    var imageFetcher : ImageFetcher!
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        imageFetcher = ImageFetcher(){ (url , image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = image
            }
            
        }
        
        session.loadObjects(ofClass: NSURL.self){
            nsurls in
            if let url = nsurls.first as? URL{
            self.imageFetcher.fetch(url)
        }
        }
        
        session.loadObjects(ofClass: UIImage.self){
                   images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
               }
        
    }
    
    
    
    
    
    
    
    
    
    
  
    
   

}
