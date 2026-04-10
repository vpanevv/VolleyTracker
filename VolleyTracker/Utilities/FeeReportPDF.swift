import UIKit
import PDFKit

/// Generates a simple fee-collection report PDF for a single group.
enum FeeReportPDF {

    struct PlayerTotal {
        let name: String
        let paidMonths: [String]   // e.g. ["Jan", "Feb"]
        let collected: Double
    }

    /// Builds the per-player totals for fees already marked as paid, and the
    /// grand total collected for the group.
    static func summary(for group: TeamGroup) -> (rows: [PlayerTotal], grandTotal: Double) {
        let fee = group.monthlyFee
        var rows: [PlayerTotal] = []

        for player in group.players.sorted(by: { $0.fullName < $1.fullName }) {
            let paidRecords = player.feeRecords
                .filter { $0.status == .paid }
                .sorted { ($0.year, $0.month) < ($1.year, $1.month) }

            guard !paidRecords.isEmpty else { continue }

            let months = paidRecords.map { "\(FeeRecord.monthNames[$0.month - 1]) \($0.year)" }
            let collected = paidRecords.reduce(0.0) { partial, rec in
                partial + (rec.amount ?? fee)
            }
            rows.append(PlayerTotal(name: player.fullName, paidMonths: months, collected: collected))
        }

        let grand = rows.reduce(0.0) { $0 + $1.collected }
        return (rows, grand)
    }

    /// Renders a PDF to a temporary file and returns its URL.
    static func generate(for group: TeamGroup) throws -> URL {
        let (rows, grandTotal) = summary(for: group)

        // Letter-size page
        let pageWidth: CGFloat  = 612
        let pageHeight: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 48

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(group.name) — Fee Collection Report",
            kCGPDFContextAuthor as String: "VolleyTracker"
        ] as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let generatedOn = dateFormatter.string(from: Date())

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.label
        ]
        let boldCellAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        let totalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.label
        ]

        // Column layout
        let contentWidth = pageWidth - margin * 2
        let nameColX  = margin
        let nameColW  = contentWidth * 0.38
        let monthsColX = nameColX + nameColW
        let monthsColW = contentWidth * 0.42
        let amountColX = monthsColX + monthsColW
        let amountColW = contentWidth * 0.20

        func formatEuro(_ value: Double) -> String {
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return "€\(Int(value))"
            }
            return String(format: "€%.2f", value)
        }

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            // Header
            let title = "\(group.emoji) \(group.name) — Fee Collection Report"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += 32

            let subtitle = "Generated \(generatedOn) · Monthly fee: \(formatEuro(group.monthlyFee))"
            subtitle.draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttrs)
            y += 24

            // Summary line
            let playerCount = rows.count
            let summaryLine = "\(playerCount) player\(playerCount == 1 ? "" : "s") have paid · Collected \(formatEuro(grandTotal)) so far"
            summaryLine.draw(at: CGPoint(x: margin, y: y), withAttributes: boldCellAttrs)
            y += 26

            // Divider
            let divider = UIBezierPath()
            divider.move(to: CGPoint(x: margin, y: y))
            divider.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.separator.setStroke()
            divider.lineWidth = 0.5
            divider.stroke()
            y += 10

            // Column headers
            "PLAYER".draw(at: CGPoint(x: nameColX, y: y), withAttributes: headerAttrs)
            "PAID MONTHS".draw(at: CGPoint(x: monthsColX, y: y), withAttributes: headerAttrs)
            let amountHeader = "COLLECTED" as NSString
            let amountHeaderSize = amountHeader.size(withAttributes: headerAttrs)
            amountHeader.draw(
                at: CGPoint(x: amountColX + amountColW - amountHeaderSize.width, y: y),
                withAttributes: headerAttrs
            )
            y += 18

            divider.removeAllPoints()
            divider.move(to: CGPoint(x: margin, y: y))
            divider.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            divider.stroke()
            y += 8

            if rows.isEmpty {
                let empty = "No fees have been collected for this group yet."
                empty.draw(at: CGPoint(x: margin, y: y), withAttributes: cellAttrs)
                y += 24
            } else {
                for row in rows {
                    // Page break if needed
                    if y > pageHeight - margin - 80 {
                        ctx.beginPage()
                        y = margin
                    }

                    let nameRect = CGRect(x: nameColX, y: y, width: nameColW - 8, height: 400)
                    (row.name as NSString).draw(in: nameRect, withAttributes: cellAttrs)

                    let monthsText = row.paidMonths.joined(separator: ", ")
                    let monthsRect = CGRect(x: monthsColX, y: y, width: monthsColW - 8, height: 400)
                    let monthsBounding = (monthsText as NSString).boundingRect(
                        with: CGSize(width: monthsColW - 8, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: cellAttrs,
                        context: nil
                    )
                    (monthsText as NSString).draw(in: monthsRect, withAttributes: cellAttrs)

                    let amountString = formatEuro(row.collected) as NSString
                    let amountSize = amountString.size(withAttributes: cellAttrs)
                    amountString.draw(
                        at: CGPoint(x: amountColX + amountColW - amountSize.width, y: y),
                        withAttributes: cellAttrs
                    )

                    let rowHeight = max(22, ceil(monthsBounding.height) + 8)
                    y += rowHeight
                }
            }

            y += 10
            divider.removeAllPoints()
            divider.move(to: CGPoint(x: margin, y: y))
            divider.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            divider.lineWidth = 1
            divider.stroke()
            y += 12

            // Grand total
            let totalLabel = "TOTAL COLLECTED"
            totalLabel.draw(at: CGPoint(x: nameColX, y: y), withAttributes: headerAttrs)

            let totalString = formatEuro(grandTotal) as NSString
            let totalSize = totalString.size(withAttributes: totalAttrs)
            totalString.draw(
                at: CGPoint(x: amountColX + amountColW - totalSize.width, y: y - 4),
                withAttributes: totalAttrs
            )
        }

        // Write to a temp file with a friendly name
        let safeName = group.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        let dateStamp = iso.string(from: Date())
        let filename = "VolleyTracker_\(safeName)_Fees_\(dateStamp).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        try data.write(to: url, options: .atomic)
        return url
    }
}

// MARK: - Share sheet wrapper

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
