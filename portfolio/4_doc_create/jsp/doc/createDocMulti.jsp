<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!-- 각 화면 개발시 Tag 복사해서 붙여넣고 사용할것 -->    
<%@ taglib prefix="c"		uri="http://java.sun.com/jsp/jstl/core"			%>
<%@ taglib prefix="tl" 	uri="/WEB-INF/tlds/tl-functions.tld"%>
<style>
.s_bt03{ background:#fff; border:1px solid #1064aa;  color:#1064aa; padding:1px 15px; border-radius: 2px; font-size: 12px;  line-height: 22px;  font-weight:bold;}
.my-row-style{
	background-color: red;
}
</style>
<script type="text/javascript">
$(document).ready(function(){
	
	//grid setting
	createAUIGrid(columnLayout);
	
	//초기 로드 시 한줄 추가
	addRow();

	//특정 화면 비율에서 처음 Grid Render시 오른쪽으로 약간 튀어나가는 현상이 있음..
	AUIGrid.resize(myGridID);
	
});

//설계변경, 프로젝트 자동완성 검색
var searchPerList = [];

//파일 저장 캐시
var primaryFileCache = {};

//문서 속성 배열
var docAttributes = null;

//문서 분류 배열
var docCodeTypes = null;

//마지막 선택한 GridItem
var recentGridItem = null;

//AUIGrid 생성 후 반환 ID
var myGridID;


//AUIGrid 칼럼 설정
var columnLayout = [
	
	{ 
		dataField : "docCodeType",
		headerText : "${tl:getMessage('문서 분류')}<span class='required'>*</span>", 
		width:"10%", 
		style:"AUIGrid_Left", 
		renderer : {
			type : "DropDownListRenderer",
			listAlign : "left",
			listFunction : function(rowIndex, columnIndex, item, dataField) {
				var listItems = [];
				for(var i = 0; i<docCodeTypes.length; i++){
					var codeType = docCodeTypes[i];
					
					if(item.referenceDoc != "${tl:getMessage('등록')}" || item.relatedPart != "${tl:getMessage('품목 선택')}"){
						
						//문서 분류가 프로젝트, 설계변경 하위인 경우 참조문서로 등록된다. 따라서 프로젝트, 설계변경은 참조문서를 따로 가질 수 없다.
						if(codeType.docCode.indexOf("02") == 0 || codeType.docCode.indexOf("03") == 0 || codeType.docCode 	== "0600"){
							continue;
						}
					}
					listItems.push(codeType);
				}
				
				return listItems;
			},
			keyField : "oid",
			valueField : "listValue",
		}},
	{ 
		dataField : "docAttribute",
		headerText : "${tl:getMessage('문서 속성 ')}<span class='required'>*</span>",	
		width:"10%", 
		style:"",
		renderer : {
			type : "DropDownListRenderer",
			listFunction : function(rowIndex, columnIndex, item, dataField) {
				var listItems = [];
				
				if(item.docCodeType != null){
					listItems = docAttributeLinks[item.docCodeType]
				}
				
				return listItems;
			},
			keyField : "oid",
			valueField : "name",
			disabledFunction :  function(rowIndex, columnIndex, value, item, dataField ) {
				
				//분류가 선택되어야 속성출력
				var code = item.docCodeType;
				
				if(code == null || code.length <= 0){
					return true;
				}
				
		        return false;
			},
		}},
	{ 
		dataField : "name", 
		headerText : "${tl:getMessage('문서 명')}<span class='required'>*</span>", 
		width:"*%",	
		style:"AUIGrid_Left",
		styleFunction :  function(rowIndex, columnIndex, value, headerText, item, dataField) {
			if(value == "${tl:getMessage('80자 이내로 작성해 주세요')}.") {
				return "my-cell-style";
			}
			return null;
		},
		editRenderer : {
			type : "InputEditRenderer",
			validator : function(oldValue, newValue, item) {
				var isValid = false;
				if(newValue.length<80){
					isValid = true;
				}
				
				return { "validate" : isValid, "message"  : "${tl:getMessage('80자 이내로 작성해 주세요')}." };
			}
		}},
	{ 
		dataField : "description",		
		headerText : "${tl:getMessage('문서 설명')}",		
		width:"*%",	 
		style:"AUIGrid_Left",
		styleFunction :  function(rowIndex, columnIndex, value, headerText, item, dataField) {
			if(value == "${tl:getMessage('200자 이내로 작성해 주세요')}.") {
				return "my-cell-style";
			}
			return null;
		},
		editRenderer : {
			type : "InputEditRenderer",
			validator : function(oldValue, newValue, item) {
				var isValid = false;
				if(newValue.length<200){
					isValid = true;
				}
				return { "validate" : isValid, "message"  : "${tl:getMessage('200자 이내로 작성해 주세요')}." };
			}
		}},
	{ 
		dataField : "mainAttachment",
		headerText : "${tl:getMessage('첨부파일')}<span class='required'>*</span>",
		width:"15%",
		style:"",
		renderer : {
			type : "ButtonRenderer",
			onclick : function(rowIndex, columnIndex, value, item) {
				fileAttachButton(item);
			}
		}},
	{ 
		dataField : "relatedPart",
		headerText : "${tl:getMessage('관련 품목')}",
		width:"10%",
		style:"",
		renderer : {
			type : "ButtonRenderer",
			onclick : function(rowIndex, columnIndex, value, item) {
				//openReferencePartPopup(item._$uid);
				add_createDocMulti_addRow();
			},
			disabledFunction :  function(rowIndex, columnIndex, value, item, dataField ) {
				
				for(var i = 0; i<docCodeTypes.length; i++){
					var codeType = docCodeTypes[i];
					if(codeType.oid == item.docCodeType){
						if(codeType.docCode.indexOf("02") == 0 || codeType.docCode.indexOf("03") == 0 || codeType.docCode == "0600"){
							return true;
						}
					}
				}
				
		        return false;
			},
		}},
	{ 
		dataField : "referenceDoc", 
		headerText : "${tl:getMessage('참조 문서')}", 
		width:"10%", 
		style:"",
		renderer : {
			type : "ButtonRenderer",
			onclick : function(rowIndex, columnIndex, value, item) {
				appendRow(item);
			},
			disabledFunction :  function(rowIndex, columnIndex, value, item, dataField ) {
				
				for(var i = 0; i<docCodeTypes.length; i++){
					var codeType = docCodeTypes[i];
					if(codeType.oid == item.docCodeType){
						if(codeType.docCode.indexOf("02") == 0 || codeType.docCode.indexOf("03") == 0 || codeType.docCode == "0600"){
							return true;
						}
					}
				}
				
		        return false;
			},
		}},
	{ 
		dataField : "eChangeProjectCode",		
		headerText : "${tl:getMessage('프로젝트/설변번호')}",		
		width:"10%", 
		style:"",
		labelFunction : function(rowIndex, columnIndex, value, headerText, item){
			
			if(item.docCodeType == null || item.docCodeType.trim() == ""){
				return "${tl:getMessage('문서 분류를 선택해 주십시오.')}"
			}
			
			if(item.eChangeProjectCode == null || item.eChangeProjectCode.trim() == ""){
				for(var i = 0; i<docCodeTypes.length; i++){
					var codeType = docCodeTypes[i];
					if(codeType.oid == item.docCodeType){
						if(codeType.docCode.indexOf("02") == 0 || codeType.docCode.indexOf("03") == 0 || codeType.docCode == "0600"){
							return "${tl:getMessage('번호를 입력해주십시오.')}";
						}else{
							return "${tl:getMessage('입력할 수 없습니다.')}"
						}
					}
				}
			}
			return item.eChangeProjectCode;
			
		},
		editRenderer : { // 편집 모드 진입 시 원격 리스트 출력하고자 할 때
		    type : "RemoteListRenderer",
		    fieldName : "number",
		    autoCompleteMode : true, // 자동완성 모드 설정 (기본값 :false)
			remoter : function( request, response ) { // remoter 반드시 지정 필수
				// 데이터 요청
				var param = new Object();
				param["keyword"] = request.term;
					
				var url = getURLString("/common/searchProjectEChangeAction");
				ajaxCallServer(url, param, function(data){
					
					
					searchPerList = data.list;
					// 그리드에 데이터 세팅
					response(data.list); 
					
				});// end of ajax
			},
			listTemplateFunction : function(rowIndex, columnIndex, text, item, dataField, listItem) {
				
				var html = '<div class="myList-style">';
				html += '<span class="myList-col" style="padding-left:10px; width:60px;" title="' + listItem.number + '">' + listItem.objTypeDisplay + '</span>';
				html += '<span class="myList-col" style="width:100px;">' + listItem.number + '</span>';
				html += '<span class="myList-col" style="width:200px; text-align:right;">' + listItem.name + '</span>';
				html += '</div>';
				
				return html;
			}
		},
	},
	{ 
		dataField : "docDirectoryDisplay",
		headerText : "${tl:getMessage('문서 경로')}", 
		width:"14%", 
		style:"AUIGrid_Left",
		styleFunction :  function(rowIndex, columnIndex, value, headerText, item, dataField) {
			if(item.isManualInputDirectory) {
				return "cell_Font_Red";
			}
			return null;
		},
	}
];


//AUIGrid 를 생성합니다.
function createAUIGrid(columnLayout) {
	
	// 그리드 속성 설정
	var gridPros = {
		
		editable : true,
			
		selectionMode : "multipleCells",
		
		rowIdField : "_$uid",

		showSelectionBorder : true,
		
		showStateColumn : false,
		
		softRemovePolicy : "exceptNew",
		
		softRemoveRowMode : false,
		
		noDataMessage : gridNoDataMessage,
		
		showRowNumColumn : true,
		
		showEditedCellMarker : false,
		
		wrapSelectionMove : true,
		
		showRowCheckColumn : true,
		
		enableFilter : true,
		
		enableMovingColumn : true,
		
		headerHeight : gridHeaderHeight,
		
		rowHeight : gridRowHeight,
		
		height : 220,
		
		rowStyleFunction : function(rowIndex, item){
			if(item.validationStyle == true){
				return "cell_Color_Red";
			}
			return "editAble_Blue_Cell";
		},
	};
	
	// 실제로 #grid_wrap 에 그리드 생성
	myGridID = AUIGrid.create("#grid_wrap", columnLayout, gridPros);
	
	
	//에디팅 시작 시 이벤트
	AUIGrid.bind(myGridID, "cellEditBegin", auiEditBeginHandler);
	
	//에디팅 종료 시 이벤트
	AUIGrid.bind(myGridID, "cellEditEnd", auiEditEndHandler);
	
	//선택이 변경되었을 때 발생하는 이벤트
	AUIGrid.bind(myGridID, "selectionChange", auiCellFocusChangeHandler);
	
	//파일 첨부 버튼 이벤트
	var fileChange = document.getElementById('file');
	fileChange.addEventListener('change', attachFile);
	
}


function auiEditBeginHandler(event){
	
	
	//수정 금지 컬럼 지정
	if(preventColumnEdit(event, ["docCodeType", "docAttribute", "mainAttachment", "relatedPart", "referenceDoc", "docDirectoryDisplay"])){
		return false;
	}
	
	if(event.dataField == "eChangeProjectCode"){
		
		if(event.item.docCodeType == null || event.item.docCodeType.trim() == ""){
			return false;
		}
		
		//프로젝트, 설계변경 외 문서는 프로젝트/설변번호 란을 입력할 필요가 없다.
		for(var i = 0; i<docCodeTypes.length; i++){
			var codeType = docCodeTypes[i];
			if(codeType.oid == event.item.docCodeType){
				if(codeType.docCode.indexOf("02") == 0 || codeType.docCode.indexOf("03") == 0 || codeType.docCode == "0600"){
				}else{
					return false;
				}
			}
		}
	}
	
	placeHolderIn(event, "name", "${tl:getMessage('80자 이내로 작성해 주세요')}.");
	placeHolderIn(event, "description", "${tl:getMessage('200자 이내로 작성해 주세요')}.");
	
}

function auiCellFocusChangeHandler(event){
	
	//마지막 포커싱 아이템 저장
	setRecentItem(event);
	
	//셀 클릭 시 해당 ROW의 참조문서, 관련품목 리스트를 뿌림
	if(recentGridItem != null){
		setRefDocList(recentGridItem._$uid);
		setRel_partCacheList(recentGridItem._$uid);
		
		//프로젝트, 설계변경 문서는 참조문서 이므로 선택 시 참조문서 란을 가린다.
		for(var i = 0; i<docCodeTypes.length; i++){
			var codeType = docCodeTypes[i];
			
			if(codeType.oid == recentGridItem.docCodeType){
				if(codeType.docCode.indexOf("02") == 0 || codeType.docCode.indexOf("03") == 0 || codeType.docCode == "0600"){
					$("#includereferenceDoc").hide();
					//AUIGrid.resize(myGridID);
					break;
				}
			}else{
				$("#includereferenceDoc").show();
				//AUIGrid.resize(myGridID);
			}
			
		}
	}
	
}

function folderValueToDocDirectory(event){
	
	if(event.type != "cellDoubleClick"){
		return;
	}
	
	var folderPath = event.item.path;
	//Default 문자열 제거
	var folderPathDisplay = folderPath.indexOf("/Default") > -1 ? folderPath.substring("/Default".length) : folderPath;
	var msg = "${tl:getMessage('')}"
	
	if(recentGridItem.docDirectory != ""){
		alert("${tl:getMessage('폴더의 경로를')}" + " " + folderPath + "${tl:getMessage('로 수정합니다.')}");
	}
	recentGridItem.docDirectory = folderPath;
	recentGridItem.docDirectoryDisplay = folderPathDisplay;
	recentGridItem.isManualInputDirectory = true;
	
	AUIGrid.updateRowsById(myGridID, recentGridItem);
}

function setRecentItem(event){
	
	var selectedItems = event.selectedItems;
	
	//하나의 아이템만 선택하지 않은 경우
	if(selectedItems.length != 1){
		recentGridItem = null;
		return;
	}else{
		recentGridItem = selectedItems[0].item;
	}
}


function openReferencePartPopup(rowId){
	
	add_createDocMulti_searchObjectPopup(rowId);
}


//캐시에 변동이 있는 경우 Label을 변경(참고 : 그리드 전체행이 UpdatedRows로 변경됨.)
function relabeling(){
	
	AUIGrid.updateAllToValue(myGridID, "relatedPart", 0);
	AUIGrid.updateAllToValue(myGridID, "referenceDoc", 0);
	
	Array.prototype.forEach.call(related_partCache, function(item, i){
		var row = AUIGrid.getItemByRowId(myGridID, item.targetRowId);
		
		if(row.relatedPart == 0){
			row.relatedPart = 0;
		}
		row.relatedPart = row.relatedPart+1;
		AUIGrid.updateRowsById(myGridID, row);
	});
	
	Array.prototype.forEach.call(referenceDocCache, function(item, i){
		
		var row = AUIGrid.getItemByRowId(myGridID, item.targetRowId);
		
		if(row.referenceDoc == 0){
			row.referenceDoc = 0;
		}
		row.referenceDoc =row.referenceDoc+1;
		AUIGrid.updateRowsById(myGridID, row);
	});
	
	var partValues = AUIGrid.getColumnValues(myGridID, "relatedPart");
	var docValues = AUIGrid.getColumnValues(myGridID, "referenceDoc");
	
	var dataList = AUIGrid.getGridData(myGridID);
	Array.prototype.forEach.call(dataList, function(data, i){
		var isEmpty = false;
		
		if(data.referenceDoc == 0){
			data.referenceDoc = "${tl:getMessage('등록')}";
			isEmpty = true;
		}
		if(data.relatedPart == 0){
			data.relatedPart = "${tl:getMessage('품목 선택')}";
			isEmpty = true;
		}
		
		if(isEmpty){
			AUIGrid.updateRowsById(myGridID, data);
		}
	});
	
}


//편집 핸들러
function auiEditEndHandler(event) {
	
	
	if(event.dataField == "docCodeType"){
		
		for(var i = 0; i<docCodeTypes.length; i++){
			var codeType = docCodeTypes[i];
			
			if(codeType.oid == event.item.docCodeType){
				
				//분류에 따른 폴더 경로를 보여준다.
				if(event.item.docDirectory!=""){
					alert("${tl:getMessage('분류에 맞는 문서 경로로 지정 하였습니다.')}")	;
				}
				event.item.docDirectoryDisplay =  codeType.folderPathDisplay;
				event.item.docDirectory = codeType.folderPath;
				event.item.isManualInputDirectory = false;
				
				
				//프로젝트, 설계변경 문서는 참조문서 이므로 선택 시 참조문서 란을 가린다.
				if(codeType.docCode.indexOf("02") == 0 || codeType.docCode.indexOf("03") == 0 || codeType.docCode == "0600"){
					$("#includereferenceDoc").hide();
					break;
				}
			}else{
				$("#includereferenceDoc").show();
			}
			
		}
		
		refDoc_getDocAttributes(event.item);
		
		event.item.docAttribute = "";
		event.item.eChangeProjectCode = "";
		event.item.eChangeProjectOid = "";
		AUIGrid.updateRowsById(myGridID, event.item);
	}
	
	if(event.dataField == "eChangeProjectCode"){
		
		if(event.item.eChangeProjectCode.trim() == ""){
			
			event.item.eChangeProjectCode = "";
			AUIGrid.updateRowsById(myGridID, event.item);
			
		}else{
			for(var i = 0; i < searchPerList.length; i++){
				
				var selectedPersistable = searchPerList[i];
				if(event.item.eChangeProjectCode == selectedPersistable.number){
					event.item.eChangeProjectOid = selectedPersistable.oid;
					AUIGrid.updateRowsById(myGridID, event.item);
				}
			}
			
		}
	}
	
	placeHolderOut(event, "name", "${tl:getMessage('80자 이내로 작성해 주세요')}.");
	placeHolderOut(event, "description", "${tl:getMessage('200자 이내로 작성해 주세요')}.");
	
};


function fileAttachButton(item){
	
	var input = $("#file");
	
	 // 파일 브라우저 열기
	input.trigger('click');
};


function attachFile(evt){
	
 	var data = null;
	var fileArr = evt.target.files;
	
	if (fileArr.length == 0) {
		delete primaryFileCache[recentGridItem._$uid];

		AUIGrid.updateRowsById(myGridID, {
			id : recentGridItem._$uid,
			mainAttachment : "${tl:getMessage('파일 선택')}"
		});
		return;
	}
	
	var file = fileArr[0];
	
	var fileN = file.name;
	var exp = fileN.substring(fileN.indexOf('.')+1);
	exp = exp.toUpperCase();
	if(exp == 'EXE' || exp == 'JS'){
		alert("${tl:getMessage('선택한 주 첨부파일은 등록할 수 없습니다.')}");
		return;
	}
	
	
	if(file.size > 209715200) {
		alert("개별 파일은 200MB 를 초과해선 안됩니다.");
		return;
	}

	// 서버로 보낼 파일 캐시에 보관
	primaryFileCache[recentGridItem._$uid] = {
		file : file
	};
	
	AUIGrid.updateRowsById(myGridID, {
		_$uid : recentGridItem._$uid,
		mainAttachment : file.name
	});

	var agent = navigator.userAgent.toLowerCase();
	if ( (navigator.appName == 'Netscape' && navigator.userAgent.search('Trident') != -1) || (agent.indexOf("msie") != -1) ){
	} else {
	    $(this).val("");
	}
	
}

//추가 버튼
function addRow() {
	
	// 그리드의 편집 인푸터가 열린 경우 에디팅 완료 상태로 만듬.
	AUIGrid.forceEditingComplete(myGridID, null);
	
	var item = new Object();
	
	item.docDirectory = "";
	item.docDirectoryDisplay = "${tl:getMessage('문서 분류를 지정하거나 좌측 폴더 트리를 더블클릭하십시오.')}";
	item.mainAttachment ="${tl:getMessage('파일 선택')}";
	item.name = "${tl:getMessage('80자 이내로 작성해 주세요')}.";
	item.description = "${tl:getMessage('200자 이내로 작성해 주세요')}.";
	item.relatedPart ="${tl:getMessage('품목 선택')}"
	item.referenceDoc = "${tl:getMessage('등록')}";
	item.eChangeProjectCode = "";
	item.eChangeProjectOid = "";
	
	AUIGrid.addRow(myGridID, item, "last");
}


//삭제 버튼
function removeRow() {

	var checkItemList = AUIGrid.getCheckedRowItems(myGridID);
	
	for(var i = 0; i < checkItemList.length; i++){
		
		//삭제된 행의 파일캐시 삭제
		delete primaryFileCache[checkItemList[i].item._$uid];
		
		//삭제된 행의 참조문서 삭제
		deleteRefDocItemByParent(checkItemList[i].item);
		
		//삭제된 행의 관련품목 삭제
		delete_partLink(checkItemList[i].item._$uid);
		
		AUIGrid.removeRowByRowId(myGridID, checkItemList[i].item._$uid);
	}
}


//저장 버튼
function save() {
	
	if(!validate()){
		return;
	}
	
	if(!checkApproveLine()) {
		return;
	}
	
	if(!confirm("${tl:getMessage('등록하시겠습니까?')}")){
		return;
	}
	
	
	//추가된 아이템들
	var addedItemList = AUIGrid.getAddedRowItems(myGridID);
	
	var param = new FormData();
	
	param.append("totalSize", addedItemList.length);
	param.append("requestModule", "DOC");
	
	//주 문서 폼 등록
	for(var i = 0; i < addedItemList.length; i++){
		
		param.append("doc_directory", addedItemList[i].docDirectory);
		param.append("row_id", addedItemList[i]._$uid);
		param.append("codetype", addedItemList[i].docCodeType);
		param.append("attribute", addedItemList[i].docAttribute);
		param.append("name", addedItemList[i].name);
		param.append("eChangeProjectOid", addedItemList[i].eChangeProjectOid);
		
		var description = addedItemList[i].description;
		if("${tl:getMessage('200자 이내로 작성해 주세요')}." == description){
			description = "";
		}
		param.append("description", description);
		
		//주 문서의 경로를 수동지정한 경우, 관련된 참조문서를 찾아서 참조문서가 주문서의 경로대로 만들어질 수 있도록 한다.
		if(addedItemList[i].isManualInputDirectory){
			for(var j = 0; j < referenceDocCache.length; j++){
				
				if(referenceDocCache[j].targetRowId == addedItemList[i]._$uid){
					referenceDocCache[j].refdoc_isManualLocation = "true";
				}
			}
		}
		
		//cacheData(OBJECT KEY) : ROW ID
		//primaryFileCache[ROW ID] : FILE OBJECT 
		Array.prototype.forEach.call(Object.keys(primaryFileCache), function(rowKey, idx){
			
			if(addedItemList[i]._$uid == rowKey){
				param.append("attachment", primaryFileCache[rowKey].file); //주첨부파일
			}
		});
		
	}
	
	//참조 문서 폼 등록
	param = refDocForming(param);
	
	//결재선 폼 등록
	param = app_line_forming(param);
	
	//관련 객체 폼 등록//related_${objType}Forming
	param = related_partForming(param);
	var url = getURLString("/doc/createDocMultiAction");
	
	callFormAjax(url, param, null, true);
	
}


//정합성 체크. 부적합한 본 문서 등록 창 Index를 반환
function getValidationIndex(rowId){
	
	var item = AUIGrid.getItemByRowId(myGridID, rowId);
	
	var rows = AUIGrid.getRowIndexesByValue(myGridID, "_$uid", rowId);

	return rows[0];
}
//정합성 체크
function validate(){
	
	//Internet Explorer에서 Set객체 사용이 불가하여 Object Key로 대체. 12345값에 의미는 없음
	var valiMainIdx = {};
	
	var valiMessage = "";
	var valiFlag = false;
	
	//본 문서
	var valiMainDocs = AUIGrid.getAddedRowItems(myGridID);
	if(valiMainDocs.length <= 0){
		alert("${tl:getMessage('등록할 문서가 없습니다.')}\n");
		return false;
	}
	Array.prototype.forEach.call(valiMainDocs, function(data, idx){
		
		var name = data.name.trim();
		var mainAttachment = data.mainAttachment;
		
		if(name == "" || name == "${tl:getMessage('80자 이내로 작성해 주세요')}."){
			//valiMainIdx.add(idx);
			valiMainIdx[idx] = 12345;
			valiFlag = true;
		}
		
		if(mainAttachment == "파일 선택"){
			valiMainIdx[idx] = 12345;
			valiFlag = true;
		}
		
		if(data.docCodeType == null){
			valiMainIdx[idx] = 12345;
			valiFlag = true;
		}
		
		if(data.docAttribute == null || data.docAttribute == ""){
			valiMainIdx[idx] = 12345;
			valiFlag = true;
		}
		
	});
	
	
	//참조 문서
	var valiRefDocs = referenceDocCache;
	for(var i = 0; i<valiRefDocs.length; i++){
		
		var data = valiRefDocs[i];
		
		var name = data.name.trim();
		var mainAttachment = data.mainAttachment;
		
		if(name == "" || name == "${tl:getMessage('80자 이내로 작성해 주세요')}."){
			valiMainIdx[(getValidationIndex(data.targetRowId))] = 12346;
			valiFlag = true;
		}
		
		if(mainAttachment == "파일 선택"){
			valiMainIdx[(getValidationIndex(data.targetRowId))] = 12346;
			valiFlag = true;
		}
		
		if(data.docCodeType == null){
			valiMainIdx[(getValidationIndex(data.targetRowId))] = 12346;
			valiFlag = true;
		}
		
		if(data.docAttribute == null){
			valiMainIdx[(getValidationIndex(data.targetRowId))] = 12346;
			valiFlag = true;
		}
	}
	
	
	//관련 품목	
	var valiParts= related_partCache;//Arr
	Array.prototype.forEach.call(valiParts, function(data, idx){
		
		var oid = data.oid;
		
		if(oid == null){
			valiMainIdx[(getValidationIndex(data.targetRowId))] = 12347;	
			valiFlag = true;
		}
	});
	
	
		
	var gridData = AUIGrid.getGridData(myGridID);
	Array.prototype.forEach.call(gridData, function(item, idx){
		
		if(valiMainIdx[idx] == null){
			item.validationStyle = false;
		}else{
			item.validationStyle = true;
		}
		AUIGrid.updateRowsById(myGridID, item);
	});
	
	if(valiFlag){
		alert("${tl:getMessage('등록에 불충분한 데이터가 있습니다.')}\n"+valiMessage);
		return false;
	}
	
	
	return true;
}



</script>
<input type="file" id="file" style="visibility:hidden;"></input>
<div class="product">
	<div class="semi_content ml30 mr30">
		<div class="semi_content2">
			<!-- pro_table -->
			<!-- //pro_table -->
			<!-- button -->
			<div class="seach_arm2 pt10 pb5">
				<div class="leftbt"><h4><img class="" src="/Windchill/jsp/portal/images/t_icon.png"> ${tl:getMessage('문서 정보')}</h4></div>
				<div class="rightbt">
					<button type="button" class="i_create" style="width:70px" onclick="addRow()">${tl:getMessage('추가')}</button>
					<button type="button" class="i_update" style="width:70px" onclick="save()">${tl:getMessage('등록')}</button>
					<button type="button" class="i_delete" style="width:70px" onclick="removeRow()">${tl:getMessage('삭제')}</button>
				</div>
			</div>
			<!-- //button -->
			<div class="list" id="grid_wrap" style="border-top:2px solid #1064aa;"></div>
		</div>
	</div>
	
	<div id="includereferenceDoc" class="ml30 mr30">
	<br/>
	<div>
		<jsp:include page="${tl:getIncludeURLString('/doc/include_addReferenceDoc')}" flush="true">
			<jsp:param name="pageName" value="createDocMulti"/>
			<jsp:param name="pageType" value="createMulti"/>
			<jsp:param name="autoGridHeight" value="false"/>
			<jsp:param name="gridHeight" value="110"/>
		</jsp:include>
	</div>
	</div>
	
	<!-- 관련 품목 지정 include 화면 -->
	<div class="ml30 mr30">
		<jsp:include page="${tl:getIncludeURLString('/common/include_addObjectMulti')}" flush="true">
			<jsp:param name="type" value="multi"/>
			<jsp:param name="objType" value="part"/>
			<jsp:param name="pageName" value="createDocMulti"/>
			<jsp:param name="gridHeight" value="110"/>
			<jsp:param name="title" value="${tl:getMessage('관련 품목')}"/>
		</jsp:include>
	</div>
	
	<div class="ml30 mr30">
		<jsp:include page="${tl:getIncludeURLString('/approval/include_addApprovalLine')}" flush="true">
			<jsp:param name="gridHeight" value="180"/>
		</jsp:include>
	</div>
</div>