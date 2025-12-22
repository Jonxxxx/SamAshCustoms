pageextension 55101 SAPaymentJournals extends "Payment Journal"
{
    layout
    {
        addafter("Bal. Account No.")
        {
            field(SAChaseCheckApplied; Rec.SAChaseCheckApplied)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify whether the Chase Check file has been generated for this journal line. This field is automatically set to Yes when you run Print Chase Check and the line is included in the generated file.';
            }
        }
    }

    actions
    {
        addlast("&Payments")
        {
            action(SAPrintChaseCheck)
            {
                AccessByPermission = TableData "Check Ledger Entry" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Print Chase Check';
                Ellipsis = true;
                Image = PrintCheck;
                ToolTip = 'Generate and download Chase Check File.';
                trigger OnAction()
                var
                    GenJournalLine: Record "Gen. Journal Line";
                    SAChaseCheckLogic: Codeunit SAChaseCheckLogic;
                begin
                    GenJournalLine.Reset();
                    GenJournalLine.Copy(Rec);
                    GenJournalLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                    GenJournalLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    SAChaseCheckLogic.PrintChaseCheck(GenJournalLine);
                    //CODEUNIT.Run(CODEUNIT::"SAChaseCheckLogic", Rec);
                end;
            }

        }

        addlast("Category_Category11")
        {
            actionref("SAPrintChaseCheck_&Payments"; SAPrintChaseCheck)
            {
            }
        }

    }


}