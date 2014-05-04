package {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;

	/**
	 * UI编辑器<br>
	 * 使用方法：UIEditor.getInstance.register(sth layer)
	 * <br>需要将TopTip换成项目适用的（淡出提示）或屏蔽之
	 * @author Zhangziran
	 */
	public class UIEditor extends Sprite {
		private static const MODE_NORMAL:int = 1
		private static const MODE_EDIT:int = 0;

		private var _txt:TextField;
		private var _mode:int;

		private var _target:DisplayObject;
		private var _display:UIEditorDisplay;
		private var _mp:Point = new Point();
		private var _tip:UIEditorTip;

		private var _stage:Stage;
		
		private static var _i:UIEditor;

		public static function getInstance():UIEditor {
			return _i ||= new UIEditor();
		}

		public function UIEditor():void {
			init();
		}

		private function init():void {
			_txt = createTextField("", 0, 100, null, 80, 20, this, null, "", true, onLink, [new GlowFilter(0x1d1812, 1, 2, 2, 5)]);
			_txt.addEventListener(MouseEvent.ROLL_OVER, onOver);
			_txt.addEventListener(MouseEvent.ROLL_OUT, onOut);
			_display = new UIEditorDisplay();
			_display.showTxt = _txt;
			_tip = new UIEditorTip();
			_tip.x = 50;
			_tip.y = 130;
			changeMode();
		}

		public function register(l:DisplayObjectContainer, stage:Stage):void {
			l.addChild(UIEditor.getInstance());
			_stage = stage;
			_display.setStage(_stage);
		}

		public function doStartOrStop():void {
			if (_mode == MODE_NORMAL) {
				startEdit();
			} else {
				stopEdit();
			}
			changeMode();
		}

		protected function onOut(event:MouseEvent):void {
			if (_tip.parent) {
				_tip.parent.removeChild(_tip);
			}
		}

		protected function onOver(event:MouseEvent):void {
			if (_tip.parent == null) {
				addChild(_tip);
			}
		}

		private function onLink(e:TextEvent):void {
			doStartOrStop();
		}

		private function changeMode():void {
			if (_mode == MODE_EDIT) {
				_mode = MODE_NORMAL;
				_txt.htmlText = linkcolor("开始编辑", "e", true, 0x00ff00, 16);
			} else {
				_mode = MODE_EDIT;
				_txt.htmlText = linkcolor("结束编辑", "o", true, 0x00ff00, 16);
			}
		}

		private function startEdit():void {
			_t = getTimer();
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove, true);
		}

		private function stopEdit():void {
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove, true);
			_display.dispose();
		}

		private var _t:int;

		private function onMove(event:MouseEvent):void {
			if (_display.type == 1) {
				return;
			}
			var t:DisplayObject = event.target as DisplayObject;
			if (getTimer() - _t > 33) {
				_t = getTimer();
				_mp.x = stage.mouseX;
				_mp.y = stage.mouseY;
				var arr:Array = _stage.getObjectsUnderPoint(_mp);
				var mt:DisplayObject = arr.pop();
				if (_display.check(mt)) {
					_stage.addChild(_display);
					_display.move = mt;
				} else {
					mt = arr.pop();
					if (_display.check(mt)) {
						_stage.addChild(_display);
						_display.move = mt;
					}
				}
			}
		}

		public static function font2(content:String, color:uint, size:int = 12):String {
			return font(content, "#" + color.toString(16), size);
		}

		private static function font(content:String, color:String, size:int = 12):String {
			return "<font color='" + color + "' size='" + size + "'>" + content + "</font>";
		}

		public static function linkcolor(content:String, params:String = "", underline:Boolean = true, color:uint = 0x00ff00, size:int = 12):String {
			return link(font2(content, color, size), params, underline);
		}

		private static function link(content:String, params:String = "", underline:Boolean = false):String {
			if (underline) {
				return "<a href='event:" + params + "'><u>" + content + "</u></a>";
			}
			return "<a href='event:" + params + "'>" + content + "</a>";
		}

		public static function createTextField(htmlText:String, x:Number, y:Number, textFormat:TextFormat = null, w:Number = NaN, h:Number = NaN, parent:DisplayObjectContainer = null, wrapperFunc:Function = null, txtName:String = "", enabled:Boolean = false, clickLinkHandler:Function = null, filter:Array = null, clickHandler:Function = null, wordWrap:Boolean = false):TextField {
			var textField:TextField = new TextField();
			textField.x = x;
			textField.y = y;
			if (!isNaN(w)) {
				textField.width = w;
			}
			if (!isNaN(h)) {
				textField.height = h;
			}
			if (textFormat != null) {
				textField.defaultTextFormat = textFormat;
			} else {
				textField.defaultTextFormat = new TextFormat("simsun", 12, 0xd6f9ff, null, null, null, null, null, "left", null, null, null, 4);
			}
			if (htmlText != null) {
				if (htmlText.indexOf("</") != -1) {
					textField.htmlText = htmlText;
				} else {
					textField.text = htmlText;
				}
			}
			if (parent) {
				parent.addChild(textField);
			}
			textField.selectable = false;
			if (enabled == false) {
				textField.mouseEnabled = false;
			}
			if (wrapperFunc != null) {
				wrapperFunc(textField);
			}
			if (txtName != "") {
				textField.name = txtName;
			}
			if (clickLinkHandler != null) {
				textField.addEventListener(TextEvent.LINK, clickLinkHandler);
			}

			if (filter != null) {
				textField.filters = filter;
			}

			if (clickHandler != null) {
				textField.addEventListener(MouseEvent.CLICK, clickHandler);
			}
			textField.wordWrap = wordWrap;
			return textField;
		}

		public static function createSprite(x:Number, y:Number, parent:DisplayObjectContainer = null):Sprite {
			var s:Sprite = new Sprite();
			s.x = x;
			s.y = y;
			if (parent) {
				parent.addChild(s);
			}
			return s;
		}

	}
}

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.utils.getQualifiedClassName;

import modules.warn.TopTip;

class UIEditorDisplay extends Sprite {
	private var _txtName:TextField;
	private var _txtInfo:TextField;

	private var _s:Sprite;

	private var _arrow:Sprite;

	private var _target:DisplayObject;
	private var _parents:Array = [];

	private var _rx:int;
	private var _ry:int;
	private var _rw:int;
	private var _rh:int;

	private var _type:int;

	private var _stage:Stage;
	private var _showTxt:TextField;

	public function UIEditorDisplay() {
		init();
	}

	private function init():void {
		_s = UIEditor.createSprite(0, 0, this);
		drawArrow();
		_txtInfo = UIEditor.createTextField("", -2, 0, null, 100, 20, this, null, "", false, null, [new GlowFilter(0x1d1812, 1, 2, 2, 5)]);
		_txtName = UIEditor.createTextField("", -2, 0, null, 100, 20, this, null, "", true, null, [new GlowFilter(0x1d1812, 1, 2, 2, 5)]);
		_txtName.autoSize = _txtInfo.autoSize = TextFieldAutoSize.LEFT;
		_txtInfo.mouseEnabled = _txtName.mouseEnabled = false;
	}

	public function setStage(s:Stage):void {
		_stage = s;
	}

	//暂时不用
	private function drawArrow():void {
		_arrow = UIEditor.createSprite(20, -8, this);
		_arrow.graphics.lineStyle(1, 0xfff000);
		_arrow.graphics.lineTo(-10, -10);
		_arrow.graphics.lineTo(-3, -10);
		_arrow.graphics.lineTo(-10, -3);
		_arrow.graphics.lineTo(-10, -10);
		_arrow.graphics.moveTo(0, 0);
		_arrow.graphics.lineTo(10, 10);
		_arrow.graphics.lineTo(3, 10);
		_arrow.graphics.lineTo(10, 3);
		_arrow.graphics.lineTo(10, 10);
		_arrow.graphics.endFill();
		_arrow.rotation = -45;
	}

	public function check(t:DisplayObject):Boolean {
		if (t == _txtName || t == _txtInfo || t == _s || t == this) {
			return false;
		}
		var qname:String = getQualifiedClassName(t);
		if (qname && qname.indexOf("::") == -1) {
			return false;
		}
		return true;
	}

	public function get target():DisplayObject {
		return _target;
	}

	public function get parents():Array {
		return _parents;
	}

	public function set showTxt(t:TextField):void {
		_showTxt = t;
	}

	//-------------------------------------------
	//move 相关
	//-------------------------------------------
	public function set move(t:DisplayObject):void {
		type = 0;
		if (_target != t) {
			_target = t;
		}
		_s.graphics.clear();
		_s.graphics.lineStyle(1, 0xffffff);
		_s.graphics.moveTo(0, 0);
		_s.graphics.lineTo(t.width, 0);
		_s.graphics.lineTo(t.width, t.height);
		_s.graphics.lineTo(0, t.height);
		_s.graphics.lineTo(0, 0);
		_s.graphics.endFill();
		_s.graphics.beginFill(0xffffff, 0.1);
		_s.graphics.drawRect(0, 0, t.width, t.height);
		_s.graphics.endFill();
		_s.addEventListener(MouseEvent.CLICK, onClick);
		var p:Point = t.localToGlobal(new Point());
		this.x = p.x;
		this.y = p.y;
		updateMove();
	}

	private function onClick(event:MouseEvent):void {
		_s.removeEventListener(MouseEvent.CLICK, onClick);
		if (_showTxt == _target && _showTxt != null) {
			UIEditor.getInstance().doStartOrStop();
			return;
		}
		target = _target;
	}

	public function updateMove():void {
		var qname:String = getQualifiedClassName(_target);
		var p:Point = _target.localToGlobal(new Point());
		this.x = p.x;
		this.y = p.y;
		_txtName.htmlText = UIEditor.font2(qname.split("::")[1], 0xffffff);
		var info:String = "x：" + _target.x + " y：" + _target.y;
		info += " w：" + _target.width + " h：" + _target.height;
		info += " sx：" + _target.scaleX + " sy：" + _target.scaleY;
		_txtInfo.htmlText = UIEditor.font2(info, 0xffffff);

		if (p.y <= 0) {
			_txtName.y = 0;
		} else {
			_txtName.y = -18;
		}
		var sy:int = _stage.stageHeight - _target.height - 20;
		if (p.y >= sy) {
			_txtInfo.y = -30;
		} else {
			_txtInfo.y = _target.height + 2;
		}
	}

	public function set target(t:DisplayObject):void {
		type = 1;
		var qname:String = getQualifiedClassName(t);
		if (qname && qname.indexOf("::") != -1) {
			_target = t;
			_parents.push(t);
			_rx = t.x;
			_ry = t.y;
			_rw = t.width;
			_rh = t.height;

			update();
			startEdit();
		} else {
			TopTip.addTip("父对象不可编辑");
		}
	}

	public function update():void {
		_s.graphics.clear();
		_s.graphics.lineStyle(1, 0xfff000);
		_s.graphics.moveTo(0, 0);
		_s.graphics.lineTo(_target.width, 0);
		_s.graphics.lineTo(_target.width, _target.height);
		_s.graphics.lineTo(0, _target.height);
		_s.graphics.lineTo(0, 0);
		_s.graphics.endFill();
		_s.graphics.endFill();
		var qname:String = getQualifiedClassName(_target);
		var p:Point = _target.localToGlobal(new Point());
		this.x = p.x;
		this.y = p.y;
		_txtName.htmlText = UIEditor.font2(qname.split("::")[1] + "（拖我）", 0xfff000);
		var info:String = "x：" + _target.x + " y：" + _target.y;
		info += " w：" + _target.width + " h：" + _target.height;
		info += " sx：" + _target.scaleX + " sy：" + _target.scaleY;
		_txtInfo.htmlText = UIEditor.font2(info, 0xfff000);
		_arrow.x = _txtName.width + 10;

		if (_isDown == false) {
			if (p.y <= 0) {
				_txtName.y = 0;
			} else {
				_txtName.y = -18;
			}
		}
		var sy:int = _stage.stageHeight - _target.height - 20;
		if (p.y >= sy) {
			_txtInfo.y = -30;
		} else {
			_txtInfo.y = _target.height + 2;
		}
	}

	private var _editing:Boolean;

	private function startEdit():void {
		if (_editing == false) {
			_editing = true;
			_txtName.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
			_txtName.addEventListener(MouseEvent.MOUSE_UP, onUp);
			_stage.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel, false, 9);
			_stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 9);
			_stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 9);
		}
	}

	private function stopEdit():void {
		_editing = false;
		_txtName.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
		_txtName.removeEventListener(MouseEvent.MOUSE_UP, onUp);
		_txtName.removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
		_stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onWheel, true);
		_stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
		_stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp, true);
		_stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		_stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, true);
		_stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	private var _isKeyShift:Boolean;

	protected function onKeyDown(e:KeyboardEvent):void {
		e.stopImmediatePropagation();
		_isKeyShift = e.shiftKey;
	}

	private function onKeyUp(e:KeyboardEvent):void {
		e.stopImmediatePropagation();
		var add:int = 1;
		if (e.shiftKey) {
			add = 10;
		}
		_isKeyShift = false
		switch (e.keyCode) {
			case W:
			case UP:
				this.y -= add;
				_target.y -= add;
				break;
			case S:
			case DOWN:
				this.y += add;
				_target.y += add;
				break;
			case D:
			case RIGHT:
				this.x += add;
				_target.x += add;
				break;
			case A:
			case LEFT:
				this.x -= add;
				_target.x -= add;
				break;
			case R:
				UIEditor.getInstance().doStartOrStop();
				break;
			case ESCAPE:
				this.dispose();
				break;
			case X:
				startFlex();
				break;
			case Z:
				onUp();
				_target.x = _rx;
				_target.y = _ry;
				_target.width = _rw;
				_target.height = _rh;
				update();
				break;
			case Q:
				if (_target.parent) {
					target = _target.parent;
				}
				break;
			case E:
				if (parents.length > 1) {
					parents.pop();
					if (parents.length > 0) {
						var p:DisplayObject = parents.pop();
						target = p;
					} else {
						TopTip.addTip("无可用子对象");
					}
				} else {
					TopTip.addTip("无可用子对象");
				}
				break;
		}
		update();
	}

	private var _flexMode:int;

	private function startFlex():void {
		if (_flexMode == 0) {
			_flexMode = 1;
			_arrow.rotation = 45;
			_arrow.visible = true;
		} else {
			_arrow.visible = true;
			_arrow.rotation = -45;
			_flexMode = 0;
		}
	}

	private function onWheel(event:MouseEvent):void {
		event.stopImmediatePropagation();
		var d:int = event.delta;
		d = d / (Math.abs(d));
		if (_isKeyShift) {
			d = d * 5;
		}
		if (_flexMode == 0) {
			_target.width += d;
		} else {
			_target.height += d;
		}
		update();
	}

	private var _startX:int;
	private var _startY:int;

	private var _isDown:Boolean;

	private function onDown(e:MouseEvent):void {
		_startX = mouseX;
		_startY = mouseY;
		_isDown = true;
		_stage.addEventListener(MouseEvent.MOUSE_MOVE, onMove);
	}

	protected function onUp(event:MouseEvent = null):void {
		_isDown = false;
		_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMove);
	}

	protected function onMove(event:MouseEvent):void {
		var newX:int = mouseX - _startX;
		this.x = this.x + newX;
		_target.x = _target.x + newX;

		var newY:int = mouseY - _startY;
		this.y = this.y + newY;
		_target.y = _target.y + newY;

		_startX = mouseX;
		_startY = mouseY;

		update();
	}

	public function clear():void {
		_s.graphics.clear();
		_txtInfo.text = _txtName.text = "";
	}

	public function dispose():void {
		clear();
		stopEdit();
		if (this.parent) {
			this.parent.removeChild(this);
		}
		_parents.length = 0;
		type = 0;
	}

	public function get type():int {
		return _type;
	}

	public function set type(value:int):void {
		_type = value;
		_arrow.visible = _type == 1;
	}


	public const BACKSPACE:int = 8;
	public const TAB:int = 9;
	public const ENTER:int = 13;
	public const COMMAND:int = 15;
	public const SHIFT:int = 16;
	public const CONTROL:int = 17;
	public const ALT:int = 18;
	public const PAUSE:int = 19;
	public const CAPS_LOCK:int = 20;
	public const ESCAPE:int = 27;

	public const SPACE:int = 32;
	public const PAGE_UP:int = 33;
	public const PAGE_DOWN:int = 34;
	public const END:int = 35;
	public const HOME:int = 36;
	public const LEFT:int = 37;
	public const UP:int = 38;
	public const RIGHT:int = 39;
	public const DOWN:int = 40;

	public const INSERT:int = 45;
	public const DELETE:int = 46;

	public const ZERO:int = 48;
	public const ONE:int = 49;
	public const TWO:int = 50;
	public const THREE:int = 51;
	public const FOUR:int = 52;
	public const FIVE:int = 53;
	public const SIX:int = 54;
	public const SEVEN:int = 55;
	public const EIGHT:int = 56;
	public const NINE:int = 57;

	public const A:int = 65;
	public const B:int = 66;
	public const C:int = 67;
	public const D:int = 68;
	public const E:int = 69;
	public const F:int = 70;
	public const G:int = 71;
	public const H:int = 72;
	public const I:int = 73;
	public const J:int = 74;
	public const K:int = 75;
	public const L:int = 76;
	public const M:int = 77;
	public const N:int = 78;
	public const O:int = 79;
	public const P:int = 80;
	public const Q:int = 81;
	public const R:int = 82;
	public const S:int = 83;
	public const T:int = 84;
	public const U:int = 85;
	public const V:int = 86;
	public const W:int = 87;
	public const X:int = 88;
	public const Y:int = 89;
	public const Z:int = 90;

	public const NUM0:int = 96;
	public const NUM1:int = 97;
	public const NUM2:int = 98;
	public const NUM3:int = 99;
	public const NUM4:int = 100;
	public const NUM5:int = 101;
	public const NUM6:int = 102;
	public const NUM7:int = 103;
	public const NUM8:int = 104;
	public const NUM9:int = 105;

	public const MULTIPLY:int = 106;
	public const ADD:int = 107;
	public const NUMENTER:int = 108;
	public const SUBTRACT:int = 109;
	public const DECIMAL:int = 110;
	public const DIVIDE:int = 111;

	public const F1:int = 112;
	public const F2:int = 113;
	public const F3:int = 114;
	public const F4:int = 115;
	public const F5:int = 116;
	public const F6:int = 117;
	public const F7:int = 118;
	public const F8:int = 119;
	public const F9:int = 120;
	public const F11:int = 122;
	public const F12:int = 123;

	public const NUM_LOCK:int = 144;
	public const SCROLL_LOCK:int = 145;

	public const COLON:int = 186;
	public const PLUS:int = 187;
	public const COMMA:int = 188;
	public const MINUS:int = 189;
	public const PERIOD:int = 190;
	public const BACKSLASH:int = 191;
	public const TILDE:int = 192; //~键

	public const LEFT_BRACKET:int = 219;
	public const SLASH:int = 220;
	public const RIGHT_BRACKET:int = 221;
	public const QUOTE:int = 222;

	public const MOUSE_BUTTON:int = 253;
	public const MOUSE_X:int = 254;
	public const MOUSE_Y:int = 255;
	public const MOUSE_WHEEL:int = 256;
	public const MOUSE_HOVER:int = 257;
}

class UIEditorTip extends Sprite {
	private var _txt:TextField;

	private var _s:Sprite;

	public function UIEditorTip() {
		_s = UIEditor.createSprite(0, 0, this);
		var str:String = UIEditor.font2("操作说明", 0xffd019, 14);
		str += "\n\n" + "非选中状态可使用游戏的快捷捷";
		str += "\n快捷点失效的话请结束编辑重新开始\n";
		str += "\n" + UIEditor.font2("拖动类名/按方向箭/WSAD", 0xffd019) + "  调整位置（shift更快）";
		str += "\n" + UIEditor.font2("Q/E", 0xffd019) + " 选中当前选中对象的parent/child";
		str += "\n" + UIEditor.font2("R", 0xffd019) + " 退出编辑模式";
		str += "\n" + UIEditor.font2("ESC", 0xffd019) + " 选中状态下可强制取消选中";
		str += "\n" + UIEditor.font2("鼠标滚轮", 0xffd019) + "  伸缩（shift 5倍速）";
		str += "\n" + UIEditor.font2("X", 0xffd019) + " 切换横/纵向伸缩";
		str += "\n" + UIEditor.font2("Z", 0xffd019) + " 可回到初始状态";
		_txt = UIEditor.createTextField(str, 5, 5, null, 285, 100, this);
		_txt.wordWrap = true;
		_txt.height = _txt.textHeight + 5;
		_s.graphics.beginFill(0x0, 0.8);
		_s.graphics.drawRect(0, 0, _txt.width + 10, _txt.height + 10);
	}
}
