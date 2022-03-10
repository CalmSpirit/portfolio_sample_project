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
	
	//팝업창 로드가 끝나면 부모창으로부터 데이터를 요청(param size가 너무 큰 경우 시간 차 고려)
	setTimeout(function(){
		opener.window.sendPopupInitData();
		
	}, 0);
	
	
	
});

window.onunload = function(){
	
	//팝업 창을 닫으면 popup변수를 초기화한다.
	opener.window.popupWindow = null;
}

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

//Jira Issue 자동완성
var searchIssueList = [];

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
				var listItems = docCodeTypes;
				return listItems;
			},
			keyField : "oid",
			valueField : "listValue",
			disabledFunction : function(rowIndex, columnIndex, value, item, dataField ) {
				if(item.outputOid.length > 0){
					return true;
				}
				
				return false;
			}
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
				
				if(item.outputOid.length > 0){
					return true;
				}
				
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
			if(value == "${tl:getMessage('40자 이내로 작성해 주세요')}.") {
				return "my-cell-style";
			}
			return null;
		},
		editRenderer : {
			type : "InputEditRenderer",
			validator : function(oldValue, newValue, item) {
				var isValid = false;
				if(newValue.length<40){
					isValid = true;
				}
				
				return { "validate" : isValid, "message"  : "${tl:getMessage('40자 이내로 작성해 주세요')}." };
			}
		}},
	{ 
		dataField : "description",		
		headerText : "${tl:getMessage('문서')} ${tl:getMessage('설명')}",		
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
				openReferencePartPopup(item._$uid);
			}
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
			}
		}},
	{ 
		dataField : "jiraIssue",
		headerText : "${tl:getMessage('Jira Issue')}", 
		width:"7%", 
		style:"AUIGrid_Left", 
		renderer : {
			type : "DropDownListRenderer",
			listAlign : "left",
			listFunction : function(rowIndex, columnIndex, item, dataField) {
				var listItems = searchIssueList;
				return listItems;
			},
			keyField : "issueId",
			valueField : "epicName",
			listTemplateFunction : function(rowIndex, columnIndex, value, item, dataField, listItem) {
				var html = '<div class="myList-style">';
				html += '<span class="myList-col" style="padding-left:10px; width:50px;" title="' + listItem.issueId + '">' + listItem.issueId + '</span>';
				html += '<span class="myList-col" style="width:200px;">' + listItem.epicName + '</span>';
				html += '<span class="myList-col" style="width:80px; text-align:right;">' + listItem.issueStateDisplay + '</span>';
				html += '</div>';

				return html;
			},
			disabledFunction : function(rowIndex, columnIndex, value, item, dataField ) {
				if(searchIssueList.length <= 0){
					return true;
				}
				
				return false;
			}
		}},
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
		
		showEditedCellMarker : true,
		
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
	
	//에디팅 취소 시 이벤트
	AUIGrid.bind(myGridID, "cellEditCancel", auiEditEndHandler);
	
	//선택이 변경되었을 때 발생하는 이벤트
	AUIGrid.bind(myGridID, "selectionChange", auiCellFocusChangeHandler);
	
	//파일 첨부 버튼 이벤트
	var fileChange = document.getElementById('file');
	fileChange.addEventListener('change', attachFile);
	
}

var projectOid = null;
function setInitData(param){
	
	projectOid = param.projectOid;
	var outputList = param.outputList;
	
	//Project Jira Issue List 가져옴
	var param = new Object();
	param["projectOid"] = projectOid;
	var url = getURLString("/project/searchJiraIssue");
	var issueData = ajaxCallServer(url, param, null);
	searchIssueList = issueData.list;
	
	// 그리드의 편집 인푸터가 열린 경우 에디팅 완료 상태로 만듬.
	//AUIGrid.forceEditingComplete(myGridID, null);
	
	var outputTemplateItems = [];
	Array.prototype.forEach.call(outputList, function(output, idx){
		
		var item = new Object();
		item.mainAttachment ="${tl:getMessage('파일 선택')}";
		
		item.name = output.outputName;
		item.description = "${tl:getMessage('200자 이내로 작성해 주세요')}.";
		item.relatedPart ="${tl:getMessage('품목 선택')}"
		item.referenceDoc = "${tl:getMessage('등록')}";
		item.outputOid = output.outputOid;
		//item.outputGate = output.gateCode;
		item.docCodeType = output.outputDocCodeTypeOid;
		item.docAttribute = output.outputDocAttributeOid;
		item.outputDirectory = output.outputLocation;
		
		item.jiraIssue = "";
		
		outputTemplateItems.push(item);
	});
	
	//setTimeout을 걸어 스케줄링에서 가장 마지막으로 실행
	setTimeout(function(){
		AUIGrid.addRow(myGridID, outputTemplateItems, "last");
		AUIGrid.refresh(myGridID);
		
		$(".aui-grid-drop-list-content").each( function() {
			$(this).css({"color": "black"});
		});
	}, 1);
	
	
}

function getGridData() {
	
} 


function auiEditBeginHandler(event){
	console.log(event);
	//수정 금지 컬럼 지정
	if(preventColumnEdit(event, ["docCodeType", "docAttribute", "mainAttachment", "relatedPart", "referenceDoc"])){
		return false;
	}
	
	placeHolderIn(event, "name", "40자 이내로 작성해 주세요.");
	placeHolderIn(event, "description", "200자 이내로 작성해 주세요.");
	
}

function auiCellFocusChangeHandler(event){
	
	//마지막 포커싱 아이템 저장
	setRecentItem(event);
	
	//셀 클릭 시 해당 ROW의 참조문서, 관련품목 리스트를 뿌림
	if(recentGridItem != null){
		setRefDocList(recentGridItem._$uid);
		setRel_partCacheList(recentGridItem._$uid);
	}
	
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
	
	add_createOutputMulti_searchObjectPopup(rowId);
}


//캐시에 변동이 있는 경우 Label을 변경(참고 : 그리드 전체행이 UpdatedRows로 변경됨.)
function relabeling(){
	console.log(referenceDocCache);	
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
	console.log(event);
	switch(event.type){
	case "cellEditEnd" :
		
		if(event.dataField == "docCodeType"){
			
			for(var i = 0; i<docCodeTypes.length; i++){
				var codeType = docCodeTypes[i];
				
				if(codeType.oid == event.item.docCodeType){
					
					event.item.outputDirectory = codeType.folderPath;
					
				}else{
					$("#includereferenceDoc").show();
				}
			}
			
			refDoc_getDocAttributes(event.item);
			
			event.item.docAttribute = "";
			AUIGrid.updateRowsById(myGridID, event.item);
		}
		
		if(event.dataField == "jiraIssue") {
			
            var item = new Object();
			Array.prototype.forEach.call(searchIssueList, function(issue, idx){
				console.log(event.value);
				if(issue.issueId == event.value){
					item = issue;
				}
				
			});
            
			// ISBN 수정 완료하면, 책제목, 저자 등의 필드도 같이 업데이트 함.
			AUIGrid.updateRow(myGridID, {
				jiraIssue : item.issueId
			}, event.rowIndex);
		}
		
		break;
	
	case "cellEditCancel" :
		break;
		
	}
	
	placeHolderOut(event, "name", "40자 이내로 작성해 주세요.");
	placeHolderOut(event, "description", "200자 이내로 작성해 주세요.");
	
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
	    // ie 일때 input[type=file] init.
	   // $('#file').replaceWith( $('#file').clone(true) );
	} else {
	    //other browser 일때 input[type=file] init.
	    $(this).val("");
	}
	
}

//추가 버튼
function addRow() {
	
	// 그리드의 편집 인푸터가 열린 경우 에디팅 완료 상태로 만듬.
	AUIGrid.forceEditingComplete(myGridID, null);
	
	var item = new Object();
	item.mainAttachment ="${tl:getMessage('파일 선택')}";
	item.name = "${tl:getMessage('40자 이내로 작성해 주세요')}.";
	item.description = "${tl:getMessage('200자 이내로 작성해 주세요')}.";
	item.relatedPart ="${tl:getMessage('품목 선택')}"
	item.referenceDoc = "${tl:getMessage('등록')}";
	item.outputOid = "";
	
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
	
	param.append("output_totalSize", addedItemList.length);
	param.append("requestModule", "OUTPUT");
	
	//주 문서 폼 등록
	for(var i = 0; i < addedItemList.length; i++){
		
		param.append("row_id", addedItemList[i]._$uid);
		param.append("output_oid", addedItemList[i].outputOid);
		param.append("output_description", addedItemList[i].description);
		param.append("output_name", addedItemList[i].name);
		param.append("output_codetype", addedItemList[i].docCodeType);
		param.append("output_attribute", addedItemList[i].docAttribute);
		param.append("output_jiraIssueId", addedItemList[i].jiraIssue);
		param.append("output_outputDirectory", addedItemList[i].outputDirectory);
		
		//cacheData(OBJECT KEY) : ROW ID
		//primaryFileCache[ROW ID] : FILE OBJECT 
		Array.prototype.forEach.call(Object.keys(primaryFileCache), function(rowKey, idx){
			
			if(addedItemList[i]._$uid == rowKey){
				param.append("output_attachment", primaryFileCache[rowKey].file); //주첨부파일
			}
		});
		
	}
	
	//참조 문서 폼 등록
	param = refDocForming(param);
	
	//결재선 폼 등록
	param = app_line_forming(param);
	
	//관련 객체 폼 등록//related_${objType}Forming
	param = related_partForming(param);
	
	var url = getURLString("/project/createOutputMultiAction");
	
	var data = callFormAjax(url, param, null, true);
	if(data.result){
		opener.location.reload();
		self.close();
	}
	
	
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
	
	var unexpectableAccess = false;
	//본 문서
	var valiMainDocs = AUIGrid.getAddedRowItems(myGridID);
	if(valiMainDocs.length <= 0){
		alert("${tl:getMessage('등록할 문서가 없습니다.')}\n");
		return false;
	}
	Array.prototype.forEach.call(valiMainDocs, function(data, idx){
		
		var name = data.name.trim();
		var mainAttachment = data.mainAttachment;
		
		if(name == "" || name == "40자 이내로 작성해 주세요."){
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
		
		if(data.outputOid == null || data.outputOid == ""){
			valiMessage += "${tl:getMessage('정상적인 접근이 아닙니다.')}\n";
			valiFlag = true;
			unexpectableAccess = true;
		}
		
	});
	
	//참조 문서
	var valiRefDocs = referenceDocCache;
	for(var i = 0; i<valiRefDocs.length; i++){
		
		var data = valiRefDocs[i];
		
		var name = data.name.trim();
		var mainAttachment = data.mainAttachment;
		
		if(name == "" || name == "40자 이내로 작성해 주세요."){
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
		
		if(unexpectableAccess){
			window.close();
		}
		return false;
	}
	
	
	return true;
}



</script>
<input type="file" id="file" style="visibility:hidden;"></input>
<div class="pop">
	<div class="semi_content pl30 pr30">
		<div class="semi_content2">
			<!-- pro_table -->
			<!-- //pro_table -->
			<!-- button -->
			<div class="seach_arm2 pt10 pb5">
				<div class="leftbt"><h4>${tl:getMessage('산출물 정보')}</h4></div>
				<div class="rightbt">
					<button type="button" class="s_update" onclick="save()">${tl:getMessage('등록')}</button>
					<button type="button" class="s_delete" onclick="removeRow()">${tl:getMessage('삭제')}</button>
				</div>
			</div>
			<!-- //button -->
			<div class="list" id="grid_wrap" style="border-top:2px solid #1064aa;"></div>
		</div>
	</div>
	<div class="pl30 pr30">
		<jsp:include page="${tl:getIncludeURLString('/doc/include_addReferenceDoc')}" flush="true">
			<jsp:param name="pageName" value="createOutputMulti"/>
			<jsp:param name="pageType" value="createMulti"/>
			<jsp:param name="autoGridHeight" value="false"/>
			<jsp:param name="gridHeight" value="110"/>
		</jsp:include>
	</div>
	
	<!-- 관련 품목 지정 include 화면 -->
	<div class="ml30 mr30">
		<jsp:include page="${tl:getIncludeURLString('/common/include_addObjectMulti')}" flush="true">
			<jsp:param name="type" value="multi"/>
			<jsp:param name="objType" value="part"/>
			<jsp:param name="pageName" value="createOutputMulti"/>
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