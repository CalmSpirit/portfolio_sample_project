<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!-- 각 화면 개발시 Tag 복사해서 붙여넣고 사용할것 -->    
<%@ taglib prefix="c"		uri="http://java.sun.com/jsp/jstl/core"			%>
<%@ taglib prefix="tl" 	uri="/WEB-INF/tlds/tl-functions.tld"%>
<script>
$(document).ready(function(){
	
	$("#beforeEditSpan").show();
	$("#editSpan").hide();
	
	getJiraIssueList();
	
	readOnlyGrid();
});

window.onunload = function(){
	//산출물 등록 창도 같이 닫는다.
	popupWindow.close();
}

//AUIGrid 생성 후 반환 ID
var outputForGate_myGridID;

//Jira Issue List
var searchIssueList = [];

//AUIGrid 칼럼 설정
var outputForGate_columnLayout = [
	{ 
		dataField : "gateName",
		headerText : "${tl:getMessage('Gate')}",
		cellMerge : true,
		style: "cell_Font_bold",
		width:"7%",
		filter : {
			showIcon : true,
			iconWidth:25
		}},
	{ 
		dataField : "outputName",
		headerText : "${tl:getMessage('산출물')}",	
		width:"15%",
		filter : {
			showIcon : true,
			iconWidth:25
		},
		renderer : {
			type : "TemplateRenderer",
		},
		labelFunction : function (rowIndex, columnIndex, value, headerText, item ) { //HTML 템플릿 작성
			
			var cellDisplay = item.outputName;
			
			if(item.outputDocOid != null && item.outputDocOid.length > 0) { 
				cellDisplay = "<a onclick=\"javascript:openView(\'" + item.outputDocOid + "\')\">" + item.outputName  +"</a>"
			}
			 
			return cellDisplay;
	    }},
	{ 
		dataField : "outputDocAttributeName",
		headerText : "${tl:getMessage('속성')}",
		width:"7%",
		filter : {
			showIcon : true,
			iconWidth:25
		}},
	{ 	
		dataField : "outputApprove",
		headerText : "${tl:getMessage('승인')}",
		width:"5%",
		filter : {
			showIcon : true,
			iconWidth:25
		},
		labelFunction : function (rowIndex, columnIndex, value, headerText, item ) { //HTML 템플릿 작성
			
			var display = "예";
			
			if(value == false){
				display = "아니오";
			}
			
			return display;
	    }},
	{ 	
		dataField : "outputEssential",
		headerText : "${tl:getMessage('필수')}",
		width:"5%",
		filter : {
			showIcon : true,
			iconWidth:25
		},
		labelFunction : function (rowIndex, columnIndex, value, headerText, item ) { //HTML 템플릿 작성
			
			var display = "예";
			
			if(value == false){
				display = "아니오";
			}
			
			return display;
	    }},
	{ 
		dataField : "outputStateDisplay",
		headerText : "${tl:getMessage('상태')}",
		width:"7%",
		filter : {
			showIcon : true,
			iconWidth:25
		}},
	{ 
		dataField : "outputDocString",
		headerText : "${tl:getMessage('문서')}",
		width:"5%",
		renderer : {
			type : "TemplateRenderer",
		},
		filter : {
			showIcon : true,
			iconWidth:25
		}},
	{ 
		dataField : "outputCreatorName",
		headerText : "${tl:getMessage('등록자')}",
		width:"7%",
		filter : {
			showIcon : true,
			iconWidth:25
		}},
	{ 
		dataField : "outputJiraIssueId",
		headerText : "${tl:getMessage('Jira Issue')}",
		width:"10%",
		style:"AUIGrid_Left",
		filter : {
			showIcon : true,
			iconWidth:25
		},
		labelFunction : function (rowIndex, columnIndex, value, headerText, item ) { //HTML 템플릿 작성
			var display = "";
			
			for(var i = 0; i < searchIssueList.length; i++){
				var jiraIssue = searchIssueList[i];
				
				if(value == jiraIssue.issueId){
					display = jiraIssue.epicName;
					break;
				}
				
				
			}
			
			return display;
	    }},
	{ 
		dataField : "outputLocationDisplay",
		headerText : "${tl:getMessage('경로')}",
		width:"15%",
		style:"AUIGrid_Left",
		filter : {
			showIcon : true,
			iconWidth:25
		}},
	{ 
		dataField : "outputDescription",
		headerText : "${tl:getMessage('설명')}",
		width:"*",
		style:"AUIGrid_Left",
		filter : {
			showIcon : true,
			iconWidth:25
		}},
];

function getJiraIssueList(){
	var param = new Object();
	param["projectOid"] = "${oid}";
	var url = getURLString("/project/searchJiraIssue");
	var issueData = ajaxCallServer(url, param, null);
	searchIssueList = issueData.list;
}

function readOnlyGrid(){
	//grid reset
	AUIGrid.destroy(outputForGate_myGridID);
	
	//그리드 그리기
	outputForGate_createAUIGrid(outputForGate_columnLayout)
	
	outputForGate_getGridData();
}


//AUIGrid 를 생성합니다.
function outputForGate_createAUIGrid(outputForGate_columnLayout) {
	
	// 그리드 속성 설정
	var gridPros = {
		
		selectionMode : "multipleCells",
		
		showSelectionBorder : true,
		
		noDataMessage : gridNoDataMessage,
		
		rowIdField : "_$uid",
		
		showRowNumColumn : false,
		
		showEditedCellMarker : false,
		
		wrapSelectionMove : true,
		
		showRowCheckColumn : true,
		
		enableFilter : true,
		
		enableMovingColumn : false,
		
		autoGridHeight : ${autoGridHeight},
		
		height : ${gridHeight},
		
		rowCheckVisibleFunction : function(rowIndex, isChecked, item) {
			if(item.outputDocOid != null && item.outputDocOid.length > 0) { 
				return false; 
			}
			return true;
		},
		
		independentAllCheckBox : true,
		
	};

	// 실제로 #grid_wrap 에 그리드 생성
	outputForGate_myGridID = AUIGrid.create("#outputForGate_grid_wrap", outputForGate_columnLayout, gridPros);
	
	
	AUIGrid.bind(outputForGate_myGridID, "rowAllCheckClick", outputForGate_auiGridAllCheckHandler);
	
	var gridData = new Array();
	AUIGrid.setGridData(outputForGate_myGridID, gridData);
	
}

function outputForGate_auiGridAllCheckHandler(event){
	
	var rowIdsArr = [];
	Array.prototype.forEach.call(AUIGrid.getGridData(outputForGate_myGridID), function(row, idx){
		var rowId = row._$uid;
		
		if(row.outputDocOid == null || row.outputDocOid.length <= 0) {
			rowIdsArr.push(rowId);
		}
		
	});
	var checkFlag = event;
	if(checkFlag){
		AUIGrid.addCheckedRowsByIds(outputForGate_myGridID, rowIdsArr);
	}else{
		AUIGrid.addUncheckedRowsByIds(outputForGate_myGridID, rowIdsArr);
	}
	
}

function outputForGate_getGridData(){

	var param = new Object();
	
	param.oid = "${oid}";
	
	AUIGrid.showAjaxLoader(outputForGate_myGridID);
	var url = getURLString("/project/getGateOutputList");
	ajaxCallServer(url, param, function(data){
    
		// 그리드 데이터
		var dataList = data.list;
		var gridData = [];
		
		AUIGrid.setGridData(outputForGate_myGridID, dataList);
        
		AUIGrid.setAllCheckedRows(outputForGate_myGridID, false);
		AUIGrid.removeAjaxLoader(outputForGate_myGridID);
	});
}

//산출물 등록 팝업 창
var popupWindow = null;
function registOutput(){
	
	var outputList = AUIGrid.getCheckedRowItemsAll(outputForGate_myGridID);
	
	if(outputList <= 0){
		alert("${tl:getMessage('등록할 대상 산출물을 선택해주세요.')}");
		return;
	}
	
	var url = getURLString("/project/createOutputMultiPopup");
	
	if(popupWindow == null){
		popupWindow = openPopup(url, "registOutput", 1600, 900);
	}else{
		popupWindow.focus();
	}
	
}

function sendPopupInitData(){
	
	var outputList = AUIGrid.getCheckedRowItemsAll(outputForGate_myGridID);
	var param = new Object();
	param.projectOid = "${oid}";
	param.outputList = outputList;
	
	popupWindow.window.setInitData(param);
}


//필터 초기화
function outputForGate_resetFilter(){
    AUIGrid.clearFilterAll(outputForGate_myGridID);
}

function outputForGate_xlsxExport() {
	AUIGrid.setProperty(outputForGate_myGridID, "exportURL", getURLString("/common/xlsxExport"));
	
	 // 엑셀 내보내기 속성
	  var exportProps = {
			 postToServer : true,
	  };
	  // 내보내기 실행
	  AUIGrid.exportToXlsx(outputForGate_myGridID, exportProps);
}

function editMode(){
	outputForGate_switchActionButtons();
	
}

function addOutputDefinition(){
	
	var url = getURLString("/project/addOutputDefinitionPopup?type=${project.productGubun}");
	
	var outDefiPopup = openPopup(url, "outputDefinition", 300, 600);
	outDefiPopup.focus();
}

function appendDefinition(newDefiList){
	
	var list = newDefiList;
	
	AUIGrid.addRow(outputForGate_myGridID, newDefiList, "last");
}

function removeOutputDefinition(){
	
	var checkItemList = AUIGrid.getCheckedRowItems(outputForGate_myGridID);
	
	var gateList = AUIGrid.getGridData(gateInfo_myGridID);
	var gateCodeArr = [];
	Array.prototype.forEach.call(gateList, function(item, idx){
		gateCodeArr.push(item.gateCode);
	});
	
	var flagEssentialOutput = false;
	for(var i = 0; i<checkItemList.length; i++){
		
		var item = checkItemList[i].item;
		
		//해당 산출물과 동일한 Gate가 프로젝트 내 존재하지 않으면 필수 산출물이여도 삭제가 가능하다.
		if(gateCodeArr.indexOf(item.gateCode) == -1){
			AUIGrid.removeRowByRowId(outputForGate_myGridID, item._$uid);
			continue;
		}
		
		if(item.outputEssential == false){
			AUIGrid.removeRowByRowId(outputForGate_myGridID, item._$uid);
		}else{
			flagEssentialOutput = true;
		}
	}
	
	if(flagEssentialOutput){
		alert("${tl:getMessage('필수 산출물은 삭제할 수 없습니다.')}");
	}
	
}

function outputForGate_switchActionButtons(){
	
	if( $('#beforeEditSpan').is(':visible') ){
		$("#beforeEditSpan").hide();
	}else{
		$("#beforeEditSpan").show();
	}
	
	if( $('#editSpan').is(':visible') ){
		$("#editSpan").hide();
	}else{
		$("#editSpan").show();
	}
	
}

function applyOutputDefinition(){
	
	
	var addedItem =	AUIGrid.getAddedRowItems(outputForGate_myGridID);
	var removedItem = AUIGrid.getRemovedItems(outputForGate_myGridID);
	
	if(addedItem.length == 0 && removedItem.length == 0){
		
		alert("변경할 사항이 없습니다.");
		outputForGate_switchActionButtons();
		readOnlyGrid();
		return;
	}
	
	var param = new Object();
	param.oid = "${oid}";
	param.addedItem = addedItem;
	param.removedItem = removedItem;
	
	var url = getURLString("/project/modifyOutputDefinitionAction");
	ajaxCallServer(url, param, function(data){
		
		if(data.result){
			outputForGate_switchActionButtons();
			readOnlyGrid();
		}
		
	}, true);
}

function cancelOutputDefinition(){
	outputForGate_switchActionButtons();
	readOnlyGrid();
}
</script>
<!-- button -->
<br/>
<div class="seach_arm2 pt10 pb5">
	<div class="leftbt"><h4><img class="pointer" onclick="switchPopupDiv(this);" src="/Windchill/jsp/portal/images/minus_icon.png"> ${tl:getMessage('GATE 별 산출물')}</h4></div>
	<div class="rightbt">
		<span id="beforeEditSpan">
			<c:if test="${(project.isProjectMember and (project.state == 'PROGRESS' or project.state == 'MODIFY' or project.state == 'STOPPING')) or tl:isAdmin()}">
			<button type="button" class="s_create" onclick="registOutput()">${tl:getMessage('산출물 등록')}</button>
			<button type="button" class="s_delete" onclick="editMode()">${tl:getMessage('산출물 정의 편집')}</button>
			</c:if>
			<button type="button" class="s_bt03" onclick="outputForGate_resetFilter();">${tl:getMessage('필터 초기화')}</button>
			<button type="button" class="s_bt03" onclick="outputForGate_xlsxExport();">${tl:getMessage('엑셀 다운로드')}</button>
		</span>
		<span id="editSpan" style="display: none;">
			<button type="button" class="s_create" onclick="addOutputDefinition()">${tl:getMessage('산출물 정의 추가')}</button>
			<button type="button" class="s_delete" onclick="removeOutputDefinition()">${tl:getMessage('산출물 정의 제거')}</button>
			<button type="button" class="s_delete" onclick="applyOutputDefinition()">${tl:getMessage('적용')}</button>
			<button type="button" class="s_delete" onclick="cancelOutputDefinition()">${tl:getMessage('취소')}</button>
		</span>
	</div>
</div>
<!-- //button -->
<div class="list" id="outputForGate_grid_wrap" style="height:${gridHeight}px">
</div>