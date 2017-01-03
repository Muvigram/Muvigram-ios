//
//  MusicTableViewCell.swift
//  Muvigram
//
//  Created by GangGongUi on 2016. 12. 5..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import MediaPlayer

class MusicTableViewCell: UITableViewCell {

    @IBOutlet weak var albumCover: UIImageView!
    @IBOutlet weak var musicTitle: UILabel!
    @IBOutlet weak var musicSinger: UILabel!
    private(set) var mpMediaItem: MPMediaItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func bind(item: MPMediaItem) {
        self.mpMediaItem = item
        if let title = item.title {
            musicTitle.text = title
        }
        if let singer = item.artist {
            musicSinger.text = singer
        }
        if let artwork = item.artwork{
            // If you have a cover
            albumCover.image = artwork.image(at: CGSize(width: 320, height: 320))
        } else {
            albumCover.image = UIImage(named: "noAlbumArt")
        }
    }
}
