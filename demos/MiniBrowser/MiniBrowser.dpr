// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2017 Salvador D�az Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)


program MiniBrowser;

{$I cef.inc}

uses
  {$IFDEF DELPHI16_UP}
  Vcl.Forms,
  {$ELSE}
  Forms,
  {$ENDIF }
  uCEFApplication,
  uCEFMiscFunctions,
  uCEFSchemeRegistrar,
  uCEFRenderProcessHandler,
  uCEFv8Handler,
  uCEFInterfaces,
  uCEFDomVisitor,
  uCEFConstants,
  uCEFTypes,
  uCEFTask,
  uMiniBrowser in 'uMiniBrowser.pas' {MiniBrowserFrm},
  uTestExtension in 'uTestExtension.pas',
  uHelloScheme in 'uHelloScheme.pas',
  uPreferences in 'uPreferences.pas' {PreferencesFrm};

{$R *.res}

var
  TempProcessHandler : TCefCustomRenderProcessHandler;

procedure DOMVisitor_OnDocAvailable(const document: ICefDomDocument);
begin
  // This function is called from a different process.
  // document is only valid inside this function.
  // As an example, this function only writes the document title to the 'debug.log' file.
  CefLog('CEF4Delphi', 1, CEF_LOG_SEVERITY_ERROR, 'document.Title : ' + document.Title);
end;

procedure ProcessHandler_OnCustomMessage(const browser: ICefBrowser; sourceProcess: TCefProcessId; const message: ICefProcessMessage);
var
  TempFrame : ICefFrame;
  TempVisitor : TCefFastDomVisitor;
begin
  if (browser <> nil) then
    begin
      TempFrame := browser.MainFrame;

      if (TempFrame <> nil) then
        begin
          TempVisitor := TCefFastDomVisitor.Create(DOMVisitor_OnDocAvailable);
          TempFrame.VisitDom(TempVisitor);
        end;
    end;
end;

procedure ProcessHandler_OnWebKitReady;
begin
{$IFDEF DELPHI14_UP}
  TCefRTTIExtension.Register('app', TTestExtension);
{$ENDIF}
end;

procedure GlobalCEFApp_OnRegCustomSchemes(const registrar: TCefSchemeRegistrarRef);
begin
  registrar.AddCustomScheme('hello', True, True, False, False, False);
end;

begin
  TempProcessHandler                 := TCefCustomRenderProcessHandler.Create;
  TempProcessHandler.MessageName     := 'retrievedom';   // same message name than TMiniBrowserFrm.VisitDOMMsg
  TempProcessHandler.OnCustomMessage := ProcessHandler_OnCustomMessage;
  TempProcessHandler.OnWebKitReady   := ProcessHandler_OnWebKitReady;

  GlobalCEFApp                      := TCefApplication.Create;
  GlobalCEFApp.RemoteDebuggingPort  := 9000;
  GlobalCEFApp.RenderProcessHandler := TempProcessHandler as ICefRenderProcessHandler;
  GlobalCEFApp.OnRegCustomSchemes   := GlobalCEFApp_OnRegCustomSchemes;
  GlobalCEFApp.LogFile              := 'debug.log';
  GlobalCEFApp.LogSeverity          := LOGSEVERITY_ERROR;

  // Examples of command line switches.
  // **********************************
  //
  // Uncomment the following line to see an FPS counter in the browser.
  //GlobalCEFApp.AddCustomCommandLine('--show-fps-counter');
  //
  // Uncomment the following line to change the user agent string.
  //GlobalCEFApp.AddCustomCommandLine('--user-agent', 'MiniBrowser');

  if GlobalCEFApp.StartMainProcess then
    begin
      CefRegisterSchemeHandlerFactory('hello', '', THelloScheme);

      Application.Initialize;
      Application.MainFormOnTaskbar := True;
      Application.CreateForm(TMiniBrowserFrm, MiniBrowserFrm);
      Application.CreateForm(TPreferencesFrm, PreferencesFrm);
      Application.Run;
    end;

  GlobalCEFApp.Free;
end.
