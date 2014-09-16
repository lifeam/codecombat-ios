//
//  editorTextStorage.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/28/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

//Thank you http://www.objc.io/issue-5/getting-to-know-textkit.html

class EditorTextStorage: NSTextStorage {
  var attributedString:NSMutableAttributedString?
  var languageProvider = LanguageProvider()
  var highlighter:NodeHighlighter!
  let language = "python"
  override init() {
    super.init()
    attributedString = NSMutableAttributedString()
    let parser = LanguageParser(scope: language, data: attributedString!.string, provider: languageProvider)
    highlighter = NodeHighlighter(parser: parser)
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func string() -> NSString? {
    return attributedString!.string
  }
  
  
  override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [NSObject : AnyObject] {
    var attributes = attributedString!.attributesAtIndex(location, effectiveRange: range)
    return attributes
  }
  
  func scopeToAttributes(scopeName:String) -> [NSObject : AnyObject]? {
    let scopes = scopeName.componentsSeparatedByString(" ")
    if contains(scopes, "comment") {
      return [NSForegroundColorAttributeName:UIColor.redColor()]
    }
    return nil
  }
  
  override func replaceCharactersInRange(range: NSRange, withString str: String) {
    attributedString!.replaceCharactersInRange(range, withString: str)
    //find a more efficient way of getting string length that isn't buggy
    let changeInLength:NSInteger = (NSString(string: str).length - range.length)
    self.edited(NSTextStorageEditActions.EditedCharacters,
      range: range,
      changeInLength: changeInLength)
  }
  
  override func setAttributes(attrs: [NSObject : AnyObject]!, range: NSRange) {
    attributedString!.setAttributes(attrs, range: range)
    self.edited(NSTextStorageEditActions.EditedAttributes,
      range: range,
      changeInLength: 0)
  }
  
  override func processEditing() {
    super.processEditing()
    //NSNotificationCenter.defaultCenter().postNotificationName("eraseParameterBoxes", object: nil, userInfo: nil)
    let parser = LanguageParser(scope: language, data: attributedString!.string, provider: languageProvider)
    highlighter = NodeHighlighter(parser: parser)
    println(highlighter.rootNode.description())
    //the most inefficient way of doing this, optimize later
    let paragraphRange = self.string()!.paragraphRangeForRange(editedRange)
    self.removeAttribute(NSForegroundColorAttributeName, range: paragraphRange)
    for var charIndex = paragraphRange.location; charIndex < NSMaxRange(paragraphRange); charIndex++ {
      let scopeName = highlighter.scopeName(charIndex)
      let scopes = scopeName.componentsSeparatedByString(" ")
      if contains(scopes, "storage.type.js") {
        let scopeExtent = highlighter.scopeExtent(charIndex)
        if scopeExtent != nil {
          println("Highlighting \(scopeExtent!.location) to \(NSMaxRange(scopeExtent!))")
          println(highlighter.rootNode.description())
          addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: scopeExtent!)
          charIndex = NSMaxRange(scopeExtent!) //may cause off by one
        }
      } else if contains(scopes, "string.quoted.double.js") {
        let scopeExtent = highlighter.scopeExtent(charIndex)
        if scopeExtent != nil {
          addAttribute(NSForegroundColorAttributeName, value: UIColor.orangeColor(), range: scopeExtent!)
          charIndex = NSMaxRange(scopeExtent!)
        }
      } else if contains(scopes, "meta.function.js") {
        let scopeExtent = highlighter.scopeExtent(charIndex)
        if scopeExtent != nil {
          println(highlighter.rootNode.description())
          println("Highlighting \(scopeExtent!.location) to \(NSMaxRange(scopeExtent!))")
          addAttribute(NSForegroundColorAttributeName, value: UIColor.purpleColor(), range: scopeExtent!)
          charIndex = NSMaxRange(scopeExtent!)
        }
      }
      if contains(scopes, "entity.name.function.js") {
        if highlighter.lastScopeNode?.parent?.name == "meta.function-call.method.with-arguments.js" {
          //println(highlighter.lastScopeNode.parent.data)
          //println("Need to put a box from \(highlighter.lastScopeNode.parent.range.location)")
          //work with a simple regex
          let endLocation = NSMaxRange(highlighter.lastScopeNode.parent.range)
          let openBracketLocation = self.string()!.rangeOfString("(", options: nil, range:NSRange(location: endLocation, length: self.string()!.length - endLocation)).location
          let closeBracketLocation = self.string()!.rangeOfString(")", options: nil, range: NSRange(location: endLocation, length: self.string()!.length - endLocation)).location
          //will break horribly, fix this hack
          NSNotificationCenter.defaultCenter().postNotificationName("drawParameterBox", object: nil, userInfo: ["rangeValue":NSValue(range: NSRange(location: openBracketLocation, length: closeBracketLocation - openBracketLocation + 1)) , "functionName":highlighter.lastScopeNode.parent.data])
        }
        let scopeExtent = highlighter.scopeExtent(charIndex)
        if scopeExtent != nil {
          addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: scopeExtent!)
        }
      }
    }
  }
}
