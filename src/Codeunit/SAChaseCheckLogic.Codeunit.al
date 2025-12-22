codeunit 55100 SAChaseCheckLogic
{
    trigger OnRun()
    begin
    end;

    procedure PrintChaseCheck(var NewGenJnlLine: Record "Gen. Journal Line")
    var
        GLSetup: Record "General Ledger Setup";
        GenJnlLine: Record "Gen. Journal Line";
        RemitAddress: Record "Remit Address";
        Vendor: Record Vendor;
        VendorLedgerEntries: Record "Vendor Ledger Entry";
        PaymentMethod: Record "Payment Method";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        LineCounter: Integer;

    Begin
        LineCounter := 0;

        //Validaciones. Abstraer
        if GLSetup.FindFirst() then;
        if GLSetup."SA Chase Check No. Series" = '' then
            Error('Chase check No. Series is not configured.');

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(FileHeaderRecord());
        OutStr.WriteText();

        GenJnlLine.Copy(NewGenJnlLine);
        if GenJnlLine.FindSet(true) then
            repeat
                PaymentMethod.Reset();
                PaymentMethod.SetFilter(Code, GenJnlLine."Payment Method Code");
                if (PaymentMethod.FindFirst()) then;
                if (PaymentMethod.SAChaseCheckFormat) and (not GenJnlLine.SAChaseCheckApplied) and
                (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Bank Account") and
                (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Vendor") then begin
                    Vendor.Reset();
                    Vendor.SetFilter("No.", GenJnlLine."Account No.");
                    if not Vendor.FindFirst() then
                        Error('Vendor %1 does not exist.', GenJnlLine."Account No.");

                    RemitAddress.Reset();
                    RemitAddress.SetFilter(Code, 'Pay');
                    RemitAddress.SetFilter("Vendor No.", GenJnlLine."Account No.");
                    if not RemitAddress.FindFirst() then
                        Error('Remit Address Pay is not configured for Vendor %1.', GenJnlLine."Account No.");

                    if (HasVendorLedgerEntry(GenJnlLine, VendorLedgerEntries)) then begin
                        OutStr.WriteText(PaymentHeaderRecord(GenJnlLine, GLSetup."SA Chase Check No. Series"));
                        OutStr.WriteText();
                        LineCounter := LineCounter + 1;

                        OutStr.WriteText(PayeeNameRecord(Vendor));
                        OutStr.WriteText();
                        LineCounter := LineCounter + 1;

                        OutStr.WriteText(PayeeAddressRecord(Vendor, RemitAddress));
                        OutStr.WriteText();
                        LineCounter := LineCounter + 1;

                        OutStr.WriteText(AdditionalPayeeAddressRecord(RemitAddress));
                        OutStr.WriteText();
                        LineCounter := LineCounter + 1;

                        OutStr.WriteText(PayeePostalRecord(RemitAddress));
                        OutStr.WriteText();
                        LineCounter := LineCounter + 1;

                        if VendorLedgerEntries.FindSet() then
                            repeat
                                OutStr.WriteText(RemittanceDetailRecord(VendorLedgerEntries));
                                OutStr.WriteText();
                                LineCounter := LineCounter + 1;
                            until VendorLedgerEntries.Next() = 0;

                        //GenJnlLine.SAChaseCheckApplied := true;
                        //GenJnlLine.Modify();
                    end;
                end;
            until GenJnlLine.Next() = 0;

        OutStr.WriteText(FileTrailerRecord(LineCounter));
        OutStr.WriteText();

        FileName := BuildChaseCheckFileName(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, 'Download', '', 'CSV Files (*.csv)|*.csv', FileName);
    End;

    local procedure BuildChaseCheckFileName(TemplateName: Code[10]; BatchName: Code[10]): Text
    var
        Timestamp: Text;
    begin
        Timestamp := Format(CurrentDateTime(), 0,
            '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>');

        exit('ChaseCheck_' +
            SanitizeFileComponent(TemplateName) + '_' +
            SanitizeFileComponent(BatchName) + '_' +
            Timestamp + '.csv');
    end;

    local procedure SanitizeFileComponent(Value: Text): Text
    begin
        // Saca caracteres inválidos para nombre de archivo en Windows
        Value := DelChr(Value, '=', '<>:"/\|?*');
        // Opcional: espacios a underscore
        Value := ConvertStr(Value, SpaceLbl, '_');
        exit(Value);
    end;

    local procedure FileHeaderRecord(): Text
    var
        Line: Text;
    begin
        Line := 'FILHDR' + LineSepLbl +
                'PWS' + LineSepLbl +
                LineSepLbl +            //Not required
                NextDay() + LineSepLbl;
        exit(Line);
    end;

    local procedure PaymentHeaderRecord(GenJnlLine: Record "Gen. Journal Line"; ChaseCheckNoSeries: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
        NoSeriesManagement: Codeunit "No. Series";
        Line: Text;
    begin
        BankAccount.Reset();
        BankAccount.SetFilter("No.", GenJnlLine."Bal. Account No.");
        if BankAccount.FindFirst() then;

        Line :=
            'PMTHDR' + LineSepLbl +
            'USPS' + LineSepLbl +
            'SAMASH' + LineSepLbl +
            NextDay() + LineSepLbl +
            FormatAmount(GenJnlLine.Amount) + LineSepLbl +
            KeepOnlyDigits(BankAccount."Bank Account No.") + LineSepLbl +
            KeepOnlyDigits(NoSeriesManagement.GetNextNo(ChaseCheckNoSeries)) + LineSepLbl +
            FormatText(GenJnlLine.Comment, 100);
        exit(Line);
    end;

    local procedure PayeeNameRecord(Vendor: Record Vendor): Text
    var
        Line: Text;
    begin
        Line :=
            'PAYENM' + LineSepLbl +
            FormatText(Vendor.Name, 35) + LineSepLbl +
            FormatText(CopyStr(Vendor.Name, 36, 35), 35) + LineSepLbl +
            Vendor."No.";
        exit(Line);
    end;

    local procedure PayeeAddressRecord(Vendor: Record Vendor; RemitAddress: Record "Remit Address"): Text
    var
        Line: Text;
    begin
        Line :=
            'PYEADD' + LineSepLbl +
            FormatText(RemitAddress.Address, 35) + LineSepLbl +
            FormatText(CopyStr(RemitAddress.Address, 36, 35), 35) + LineSepLbl +
            Vendor."Phone No.";
        exit(Line);
    end;

    local procedure AdditionalPayeeAddressRecord(RemitAddress: Record "Remit Address"): Text
    var
        Line: Text;
    begin
        Line :=
            'ADDPYE' + LineSepLbl +
            FormatText(RemitAddress."Address 2", 35) + LineSepLbl +
            FormatText(CopyStr(RemitAddress."Address 2", 36, 35), 35);
        exit(Line);
    end;

    local procedure PayeePostalRecord(RemitAddress: Record "Remit Address"): Text
    var
        Line: Text;
    begin
        Line :=
            'PYEPOS' + LineSepLbl +
            FormatText(RemitAddress.City, 35) + LineSepLbl +
            FormatText(RemitAddress.County, 35) + LineSepLbl +
            FormatText(RemitAddress."Post Code", 10) + LineSepLbl +
            FormatText(RemitAddress."Country/Region Code", 3);
        exit(Line);
    end;

    local procedure RemittanceDetailRecord(VendorLedgerEntries: Record "Vendor Ledger Entry"): Text
    var
        Line: Text;
    begin
        Line :=
            'RMTDTL' + LineSepLbl +
            FormatText(VendorLedgerEntries."Document No.", 30) + LineSepLbl +
            FormatText(VendorLedgerEntries.Description, 30) + LineSepLbl +
            FormatDate(VendorLedgerEntries."Posting Date") + LineSepLbl +
            FormatAmount(Abs(VendorLedgerEntries."Amount to Apply") - Abs(VendorLedgerEntries."Original Pmt. Disc. Possible")) + LineSepLbl +
            FormatAmount(Abs(VendorLedgerEntries."Amount to Apply")) + LineSepLbl +
            FormatAmount(Abs(VendorLedgerEntries."Original Pmt. Disc. Possible")) + LineSepLbl;
        exit(Line);
    end;

    local procedure HasVendorLedgerEntry(GenJnlLine: Record "Gen. Journal Line"; var VendorLedgerEntries: Record "Vendor Ledger Entry"): Boolean
    begin
        VendorLedgerEntries.Reset();
        VendorLedgerEntries.SetFilter("Vendor No.", GenJnlLine."Account No.");
        if GenJnlLine."Applies-to ID" <> '' then begin
            VendorLedgerEntries.SetFilter("Applies-to ID", GenJnlLine."Applies-to ID");
        end else
            if (GenJnlLine."Applies-to Doc. No." <> '') then begin
                VendorLedgerEntries.SetFilter("Document No.", GenJnlLine."Applies-to Doc. No.");
                VendorLedgerEntries.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            end else
                exit(false);
        exit(not VendorLedgerEntries.IsEmpty());
    end;

    local procedure FileTrailerRecord(LineCounter: Integer): Text
    var
        Line: Text;
    begin

        Line := 'FILTRL' + LineSepLbl + PadStr(Format(LineCounter + 2), 6, SpaceLbl); //Header + LineCounter +Trailer
        exit(Line);
    end;

    local procedure NextDay(): Text
    var
        TomorrowTxt: Text;
    begin
        TomorrowTxt := FormatDate(Today() + 1);
        exit(TomorrowTxt)
    end;

    local procedure FormatDate(Date: Date): Text
    var
        DateText: Text;
    begin
        DateText := Format(Date, 0, '<Month,2>/<Day,2>/<Year4,4>');
        exit(DateText)
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, '<Standard Format,9>'));
    end;

    local procedure FormatText(CommentText: Text; MaxLen: Integer): Text
    var
        i: Integer;
        Ch: Char;
        OutText: Text;
    begin

        OutText := '';

        if CommentText = '' then
            exit('');

        for i := 1 to StrLen(CommentText) do begin
            Ch := CommentText[i];

            case Ch of
                9,   // TAB
                10,  // LF
                13,  // CR
                124: // '|'
                    OutText += SpaceLbl;
                else
                    OutText += Ch;
            end;

            if (MaxLen > 0) and (StrLen(OutText) >= MaxLen) then
                break;
        end;

        // Si contiene coma, encerrar entre pipes
        if StrPos(OutText, ',') > 0 then
            exit('|' + OutText + '|');

        exit(OutText);
    end;

    local procedure KeepOnlyDigits(Source: Text): Text
    var
        i: Integer;
        ResultTxt: Text;
        Ch: Char;
    begin
        ResultTxt := '';

        for i := 1 to StrLen(Source) do begin
            Ch := Source[i];
            if (Ch >= '0') and (Ch <= '9') then
                ResultTxt += CopyStr(Source, i, 1);
        end;

        exit(ResultTxt);
    end;

    var
        LineSepLbl: Label ',';
        SpaceLbl: Label ' ';
}