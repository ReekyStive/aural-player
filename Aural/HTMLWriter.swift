import Foundation

class HTMLText {
    
    var text: String
    
    var underlined: Bool
    var bold: Bool
    var italic: Bool
    
    var width: Int?
    
    init(_ text: String, _ bold: Bool, _ underlined: Bool, _ italic: Bool, _ width: Int?) {
        
        self.text = text
        
        self.underlined = underlined
        self.bold = bold
        self.italic = italic
        
        self.width = width
    }
}

class HTMLWriter {
    
    private var data: String = "<html>\n"
    
    func addTitle(_ title: String) {
        data.append(String(format: "\t<head><title>%@</title></head>\n", title))
    }
    
    func addHeading(_ heading: String, _ size: Int, _ underlined: Bool = false) {
        
        if underlined {
            data.append(String(format: "\t<h%d><u>%@</u></h%d>\n", size, heading, size))
        } else {
            data.append(String(format: "\t<h%d>%@</h%d>\n", size, heading, size))
        }
    }
    
    func addParagraph(_ text: HTMLText) {
        
        let _text = String(format: "\t\t\t%@%@%@%@%@%@%@\n", text.underlined ? "<u>" : "", text.bold ? "<b>" : "", text.italic ? "<i>" : "", text.text.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"), text.underlined ? "</u>" : "", text.bold ? "</b>" : "", text.italic ? "</i>" : "").replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "<br>")
        
        data.append(String(format: "\t<p>%@</p>\n", _text))
    }
    
    func addLineBreak() {
        data.append("\t<br>\n")
    }
    
    func addTable(_ heading: String, _ headingSize: Int, _ columnHeaders: [String]?, _ rows: [[HTMLText]], _ horizPadding: Int = 0, _ vertPadding: Int = 0) {

        // Table heading
        data.append(String(format: "\t<h%d><u>%@</u></h%d>\n", headingSize, heading, headingSize))
        
        // Column headers
        data.append(String(format: "\t<table>\n"))
        
        if let headers = columnHeaders {
            
            data.append(String(format: "\t\t<tr>\n"))
            
            for header in headers {
                data.append(String(format: "\t\t\t<th>%@</th>\n", header))
            }
            
            data.append(String(format: "\t\t</tr>\n"))
        }
        
        // Table body
        for row in rows {
        
            data.append(String(format: "\t\t<tr>\n"))
            
            for column in row {
                
                let widthMarkup = column.width != nil ? String(format: "width:%dpx;", column.width!) : ""
                let hPaddingMarkup = horizPadding > 0 ? String(format: "padding-right:%dpx;", horizPadding) : ""
                let vPaddingMarkup = vertPadding > 0 ? String(format: "padding-bottom:%dpx", vertPadding) : ""
                
                let tdMarkup = String(format: " style=\"%@%@%@\"", widthMarkup, hPaddingMarkup, vPaddingMarkup)
                
                column.text = column.text.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
                
                data.append(String(format: "\t\t\t<td%@>%@%@%@%@%@%@%@</td>\n", tdMarkup, column.underlined ? "<u>" : "", column.bold ? "<b>" : "", column.italic ? "<i>" : "", column.text, column.underlined ? "</u>" : "", column.bold ? "</b>" : "", column.italic ? "</i>" : ""))
            }
            
            data.append(String(format: "\t\t</tr>\n"))
        }
        
        data.append(String(format: "\t</table>\n"))
    }
    
    func writeToFile(_ file: URL, _ failSilently: Bool = false) throws {
        
        data.append("</html>")
        
        do {
            
            try data.write(to: file, atomically: false, encoding: String.Encoding.utf8)
            
        } catch let error as NSError {
            
            if failSilently {
                NSLog("Error writing HTML object to file: %@", error.description)
            } else {
                throw HTMLWriteError(description: error.description)
            }
        }
    }
}

class HTMLWriteError: Error, DisplayableError {
    
    var message: String
    var description: String
    
    init(description: String) {
        
        self.description = description
        self.message = "Error writing HTML object to file"
    }
}