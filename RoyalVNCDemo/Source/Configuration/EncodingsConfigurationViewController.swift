import Foundation
import AppKit

import RoyalVNCKit

class EncodingsConfigurationViewController: NSViewController {
	@IBOutlet private weak var tableView: NSTableView!
	
	private var didLoad = false
	
	let supportedFrameEncodings: [VNCFrameEncodingType]
	
	var frameEncodings: [VNCFrameEncodingType] {
		didSet {
			tableView.reloadData()
		}
	}
	
	private var orderedFrameEncodings: [VNCFrameEncodingType] {
		let encs = orderedEncodings(encodings: supportedFrameEncodings,
									order: frameEncodings)
		
		return encs
	}
	
	init(supportedFrameEncodings: [VNCFrameEncodingType]) {
		self.supportedFrameEncodings = supportedFrameEncodings
		self.frameEncodings = supportedFrameEncodings
		
		super.init(nibName: "EncodingsConfigurationView", bundle: .main)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard !didLoad else { return }
		didLoad = true
		
		tableView.dataSource = self
		tableView.delegate = self
	}
	
	@IBAction private func checkBoxEncoding_action(_ sender: NSButton) {
		let row = tableView.row(for: sender)
		
		guard row != NSNotFound,
			  row >= 0 else {
			return
		}
		
		let encoding = orderedFrameEncodings[row]
		let isEnabled = sender.state == .on
		
		setEncoding(encoding,
					index: row,
					enabled: isEnabled)
	}
	
	@IBAction private func buttonMoveUp_action(_ sender: NSButton) {
		let row = tableView.selectedRow
		
		guard row != NSNotFound,
			  row >= 0 else {
			return
		}
		
		moveEncoding(atIndex: row,
					 up: true)
	}
	
	@IBAction private func buttonMoveDown_action(_ sender: NSButton) {
		let row = tableView.selectedRow
		
		guard row != NSNotFound,
			  row >= 0 else {
			return
		}
		
		moveEncoding(atIndex: row,
					 up: false)
	}
	
	func orderedEncodings(encodings: [VNCFrameEncodingType],
						  order: [VNCFrameEncodingType]) -> [VNCFrameEncodingType] {
		order.filter { encodings.contains($0) } + encodings.filter { !order.contains($0) }
	}
	
	func setEncoding(_ encoding: VNCFrameEncodingType,
					 index: Int,
					 enabled isEnabled: Bool) {
		if isEnabled {
			if index < frameEncodings.count {
				frameEncodings.insert(encoding, at: index)
			} else {
				frameEncodings.append(encoding)
			}
		} else {
			frameEncodings.remove(at: index)
		}
		
		tableView.reloadData()
	}
	
	func moveEncoding(atIndex index: Int,
					  up: Bool) {
		guard index >= 0,
			  index < frameEncodings.count else {
			return
		}
		
		let newIndex = up
			? max(index - 1, 0)
			: min(index + 1, frameEncodings.count - 1)
		
		let encoding = frameEncodings.remove(at: index)
		
		frameEncodings.insert(encoding, at: newIndex)
		
		tableView.reloadData()
		tableView.selectRowIndexes(.init(integer: newIndex), byExtendingSelection: false)
	}
}

extension EncodingsConfigurationViewController: NSTableViewDelegate, NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		orderedFrameEncodings.count
	}
	
	func tableView(_ tableView: NSTableView,
				   viewFor tableColumn: NSTableColumn?,
				   row: Int) -> NSView? {
		let encoding = orderedFrameEncodings[row]
		
		guard let cellView = tableView.makeView(withIdentifier: .init("EncodingCell"), owner: nil),
			  let checkBox = cellView.viewWithTag(450) as? NSButton else {
			return nil
		}

		let title = encoding.description
		let isEnabled = frameEncodings.contains(encoding)
		
		checkBox.title = title
		checkBox.state = isEnabled ? .on : .off
		
		checkBox.target = self
		checkBox.action = #selector(checkBoxEncoding_action(_:))
		
		return cellView
	}
	
	func tableView(_ tableView: NSTableView,
				   isGroupRow row: Int) -> Bool {
		return false
	}
}
