<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!-- 각 화면 개발시 Tag 복사해서 붙여넣고 사용할것 -->    
<%@ taglib prefix="c"		uri="http://java.sun.com/jsp/jstl/core"			%>
<%@ taglib prefix="tl" 	uri="/WEB-INF/tlds/tl-functions.tld"%>
<style>
.SumoSelect {
    width: 58%;
}
</style>
<script>
$(document).ready(function(){
	
	
	//프로젝트 유형 option 가져오기
	getProjectGateList();
	
	//getProjectStateList();
	getLifecycleList("LC_Project");

	//비동기 처리 
	setTimeout(function(){
		
		//프로젝트 상태 select option 기본값
		$("#state")[0].sumo.selectItem("PROGRESS");
		
		$("#searchForm").keypress(function(e){
			if(e.keyCode==13){
				search();
			}
		});
		
		drawDynamicGrid();
	}, 0);
	
});




//AUIGrid 생성 후 반환 ID
var myGridID;

//현재 페이지
var page = 1;

//row 로딩 개수
var rows = 20;

// 중복 요청을 피하기 위한 플래그
var nowRequesting = false;

//마지막 페이지 여부
var isLastPage = false;

//소트 값
var sortValue = "";

//소트 값으로 소팅되었는지 체크하는 값
var sortCheck = true;

//AUIGrid 칼럼 설정
var columnLayout = [];

//선택한 프로젝트 유형 하위의 게이트 리스트
var selectedGateList = [];


function drawDynamicGrid(){
	
	currentSituation_columnLayout();
	createAUIGrid(columnLayout);
	getGridData();
	
}


//Gate 설정에 따른 ColumnLayout 동적 처리(Gate는 NumberCode가 아닌 OutputTypeStep의 규칙을 따릅니다.)
function currentSituation_columnLayout(){
	
	columnLayout = [];
	
	var productGubun = $("#productGubun").val();
	
	var gateSearch = new Object();
	if($('#searchDisabled').is(':checked')){
		gateSearch.searchDisabled = true;
	}
	
	var allGate = getGateList(gateSearch);
	
	var gateList = [];
	
	Array.prototype.forEach.call(allGate, function(gate, idx){
		
		if(gate.parentGateCode == productGubun){
			gateList.push(gate);
		}
	});
	
	selectedGateList = gateList;
	
	//////////////////// NO ////////////////////
	var columnProp = new Object();
	columnProp.dataField = "rowNumber";
	columnProp.headerText = "No.";
	columnProp.width = "3%"
	columnProp.cellMerge = true;
	var dataFieldRowNumber = createLayoutObject(columnProp);
	//columnLayout = insertLayoutObject(columnLayout, dataFieldRowNumber);
	columnLayout.push(dataFieldRowNumber);
	
	//////////////////// 프로젝트 ////////////////////
	var nameRenderer = new Object();
	nameRenderer.type = "LinkRenderer";
	nameRenderer.baseUrl = "javascript";
	nameRenderer.jsCallback = function(rowIdx, colIdx, value, item){
		var oid = item.oid;
		openView(oid);
	};
	columnProp = new Object();
	columnProp.dataField = "name";
	columnProp.headerText = "프로젝트";
	columnProp.mergePolicy = "restrict";
	columnProp.mergeRef = "rowNumber";
	columnProp.cellMerge = true;
	columnProp.renderer = nameRenderer;
	var dataFieldProjectName = createLayoutObject(columnProp);
	//columnLayout = insertLayoutObject(columnLayout, dataFieldProjectName);
	columnLayout.push(dataFieldProjectName);
	
	
	
	//////////////////// MM ////////////////////
	columnProp = new Object();
	columnProp.dataField = "expenseMM";
	columnProp.headerText = "MM";
	columnProp.mergePolicy = "restrict";
	columnProp.mergeRef = "rowNumber";
	columnProp.cellMerge = true;
	columnProp.width = "4%"
	var dataExpenseMM = createLayoutObject(columnProp);
	//columnLayout = insertLayoutObject(columnLayout, dataExpenseMM);
	columnLayout.push(dataExpenseMM);
	
	
	//////////////////// GATE 관련 열 ////////////////////
	var gateStyleFunction = function(rowIndex, columnIndex, value, headerText, item, dataField) {
		
		var compareMode = $("input:radio[id='compareDate']:checked").val();
		
		if(item.rowType == "color"){
			
			if(item[dataField+compareMode+"_DELAYED"] == true){             
				return "cell_Color_Red2";                      
			}                                                  
			                                                   
			//10002:Done
			if(item[dataField+"STATEKEY"] == "10002"){         
				return "cell_Color_Gray";                     
			}
			//1:Open,  10306:Todo
			if(item[dataField+"STATEKEY"] == "10306" || item[dataField+"STATEKEY"] == "1" ){         
				return "cell_Color_Green";                      
			}                                 
			//3:In Process, 10001:In Review
			if(item[dataField+"STATEKEY"] == "3" || item[dataField+"STATEKEY"] == "10001"){             
				return "cell_Color_Blue";                      
			}                                                  
			
		}
		
		if(item.rowType == "date"){
			
			if(item[dataField] != "-"){
				return "AUIGrid_Left";
			}
		}
		
		return "";
	}
	
	var gateLabelFunction = function(rowIndex, columnIndex, value, headerText, item, dataField) {
		
		var compareMode = $("input:radio[id='compareDate']:checked").val();
		
		if(item.rowType == "date" && item[dataField+"STATEKEY"] != null){
			
			var realEndDate = item[dataField+"REALED"];
			
			
			var displayString = "";
			
			
			var planEd = item[dataField+"PLANED"] == null ? "-" : item[dataField+"PLANED"];
			var estiEd = item[dataField+"ESTIED"] == null ? "-" : item[dataField+"ESTIED"];
			var realEd = item[dataField+"REALED"] == null ? "-" : item[dataField+"REALED"];
			
			
			var isPlan = false;
			if(compareMode == "PLAN"){
				isPlan = true;
			}
			
			if(isPlan){
				displayString += "<u>";
			}
			displayString += "계획 종료일 : "+ planEd;
			if(isPlan){
				displayString += "</u>";
			}
			displayString += "<br/>";
			if(!isPlan){
				displayString += "<u>";
			}
			displayString += "추정 종료일 : "+ estiEd;
			if(!isPlan){
				displayString += "</u>";
			}
			displayString += "<br/>";
			displayString += "실제 종료일 : "+ realEd;
			
			
			var realString ="";
			return displayString;
		}
		
		return value;
	}
	
	var gateRenderer = new Object();
	gateRenderer.type = "TemplateRenderer";
	
	
	Array.prototype.forEach.call(selectedGateList, function(gate, idx){
		columnProp = new Object();
		columnProp.dataField = gate.gateCode;
		columnProp.headerText = gate.gateName;
		columnProp.styleFunction = gateStyleFunction;
		columnProp.labelFunction = gateLabelFunction;
		columnProp.renderer = gateRenderer;
		
		var layoutObject = createLayoutObject(columnProp);
		//columnLayout = insertLayoutObject(columnLayout, layoutObject);
		columnLayout.push(layoutObject);
	});
	
	
	//////////////////// 개발 제품 명 ////////////////////
	columnProp = new Object();
	columnProp.dataField = "productType";
	columnProp.headerText = "개발제품";
	columnProp.mergePolicy = "restrict";
	columnProp.mergeRef = "rowNumber";
	columnProp.cellMerge = true;
	var dataProductType = createLayoutObject(columnProp);
	//columnLayout = insertLayoutObject(columnLayout, dataProductType);
	columnLayout.push(dataProductType);
	
	
	//////////////////// 관련 제품 ////////////////////
	columnProp = new Object();
	columnProp.dataField = "relatedPartString";
	columnProp.headerText = "관련 제품";
	columnProp.mergePolicy = "restrict";
	columnProp.mergeRef = "rowNumber";
	columnProp.cellMerge = true;
	columnProp.renderer = gateRenderer;
	columnProp.style = "AUIGrid_Left";
	var dataRelatedPart = createLayoutObject(columnProp);
	//columnLayout = insertLayoutObject(columnLayout, dataRelatedPart);
	columnLayout.push(dataRelatedPart);
	
	
}


//AUIGrid 를 생성합니다.
function createAUIGrid(columnLayout) {
	
	// 그리드 속성 설정
	var gridPros = {
		
		selectionMode : "multipleCells",
		
		showSelectionBorder : true,
		
		noDataMessage : gridNoDataMessage,
		
		rowIdField : "_$uid",
		
		showRowNumColumn : false,
		
		showEditedCellMarker : false,
		
		wrapSelectionMove : true,
		
		showRowCheckColumn : false,
		
		enableFilter : false,
		
		enableMovingColumn : false,
		
		headerHeight : gridHeaderHeight,
		
		rowHeight : 55,
		
		enableCellMerge : true,
		
		cellMergePolicy : "withNull",
		
		//한 줄 건너서 회색 칠하는거
		rowStyleFunction : function(rowIndex, item){
			
			var isOddRow = parseInt( item.rowNumber ) % 2 == 1 ? true : false;
			
			if(isOddRow){
				return "cell_Color_Gray2";
			}
			return "cell_Color_White";
		},
		
		wheelSensitivity : 2,
		
		height : 560
	};

	// 실제로 #grid_wrap 에 그리드 생성
	myGridID = AUIGrid.create("#grid_wrap", columnLayout, gridPros);
	
	// 셀 클릭 이벤트 바인딩
	AUIGrid.bind(myGridID, "cellClick", auiGridCellClickHandler);
	
	// 스크롤 체인지 이벤트 바인딩
	AUIGrid.bind(myGridID, "vScrollChange", vScollChangeHandelr);
	
	// 헤더 클릭 이벤트 바인딩
	AUIGrid.bind(myGridID, "headerClick", auiGridHeaderClickHandler);
	
}

function getGridData(){
	
	$("#searchForm").attr("action", getURLString("/project/projectCurrentSituationScrollAction"));
	
	var param = new Object();
	
	param["page"] = page;
	param["rows"] = rows;
	param["sortValue"] = sortValue;
	param["sortCheck"] = sortCheck;
	
	if(page == 1) {
		AUIGrid.showAjaxLoader(myGridID);
	}
	
	formSubmit("searchForm", param, null, function(data){
		
		// 그리드 데이터
		var gridData = data.list;
		var dataLength = gridData.length;
		
		var count = $("#count").html();		
		
		gridData = toBarChart(gridData);
		
		if(page == 1) {
			// 그리드에 데이터 세팅(첫 요청)
			AUIGrid.setGridData(myGridID, gridData);	
			
			count = dataLength;
		} else {
			// 그리드에 데이터 세팅(추가 요청)
			AUIGrid.appendData(myGridID, gridData);
			
			count = parseInt(count) + dataLength;
		}
		
		
		$("#count").html(count);
		$("#total").html(data.totalSize);
		$("#sessionId").val(data.sessionId);
		
		if(gridData.length == 0) {
			isLastPage = true;
		}
		
		
		AUIGrid.removeAjaxLoader(myGridID);
		
		nowRequesting = false;
	});
}

function toBarChart(gridData){
	
	if(gridData != null){
		
		var barChartData = [];
		
		for(var i = 0; i<gridData.length; i++){
			
			var data = gridData[i];
			
			var projectOid = data.oid == null ? "" : data.oid; 
			var projectName = data.name == null ? "" : data.name;
			var expenseMM = data.expenseMM == null || data.expenseMM == "null" ? "" : data.expenseMM;
			
			var gateState = data.gateState == null ? new Object() : data.gateState;
			var gateStateDisplay = data.gateStateDisplay == null ? new Object() : data.gateStateDisplay;
			var gatePlanStartDate = data.gatePlanStartDate == null ? new Object() : data.gatePlanStartDate;
			var gatePlanEndDate = data.gatePlanEndDate == null ? new Object() : data.gatePlanEndDate;
			var gateEstiStartDate = data.gateEstimateStartDate == null ? new Object() : data.gateEstimateStartDate;
			var gateEstiEndDate = data.gateEstimateEndDate == null ? new Object() : data.gateEstimateEndDate;
			var gateRealStartDate = data.gateRealStartDate == null ? new Object() : data.gateRealStartDate;
			var gateRealEndDate = data.gateRealEndDate == null ? new Object() : data.gateRealEndDate;
			var productType = data.productType == null ? "" : data.productType;
			var relatedPartString = data.relatedPartString == null ? "" : data.relatedPartString;
			
			var planGateDelayed = data.gatePlanDelayed == null ? new Object() : data.gatePlanDelayed;
			var estiGateDelayed = data.gateEstimateDelayed == null ? new Object() : data.gateEstimateDelayed;
			
			var colorLine = new Object();
			var count = parseInt($("#count").html());
			
			colorLine["rowType"] = "color";
			colorLine["rowNumber"] = count + 1 + i;
			colorLine["oid"] = projectOid;
			colorLine["name"] = projectName;
			colorLine["expenseMM"] = expenseMM;
			colorLine["productType"] = productType;
			colorLine["relatedPartString"] = relatedPartString;
			
			var dateLine = new Object();
			dateLine["rowType"] = "date";
			dateLine["rowNumber"] = count + 1 + i;
			dateLine["oid"] = projectOid;
			dateLine["name"] = projectName;
			dateLine["expenseMM"] = expenseMM;
			dateLine["productType"] = productType;
			dateLine["relatedPartString"] = relatedPartString;
			
			Array.prototype.forEach.call(Object.keys(gateState), function(key, i){
				colorLine[key+"PLAN_DELAYED"] = planGateDelayed[key];
				colorLine[key+"ESTI_DELAYED"] = estiGateDelayed[key];
				colorLine[key+"STATEKEY"] = gateState[key];
				colorLine[key] = gateStateDisplay[key];
				
				dateLine[key+"STATEKEY"] = gateState[key];
				dateLine[key+"PLANSD"] = gatePlanStartDate[key];
				dateLine[key+"PLANED"] = gatePlanEndDate[key];
				dateLine[key+"ESTISD"] = gateEstiStartDate[key];
				dateLine[key+"ESTIED"] = gateEstiEndDate[key];
				dateLine[key+"REALSD"] = gateRealStartDate[key];
				dateLine[key+"REALED"] = gateRealEndDate[key];
			});
			
			barChartData.push(colorLine);
			barChartData.push(dateLine);
		}
			
	}
	
	gridData = barChartData;
	return gridData;
}

function changeCompare(change){
	
	AUIGrid.refresh(myGridID);
}

//셀 클릭 핸들러
function auiGridCellClickHandler(event) {
	
	var dataField = event.dataField;
	var oid = event.item.oid;
	
}

//헤더 클릭 핸들러
function auiGridHeaderClickHandler(event) {
	
	//헤더 클릭 시 정렬 안함
	return false;
}

//스크롤 체인지 핸들어에서 무리한 작업을 하면 그리드 퍼포먼스가 떨어집니다.
//따라서 무리한 DOM 검색은 자제하십시오.
function vScollChangeHandelr(event) {
	
	// 스크롤 위치가 마지막과 일치한다면 추가 데이터 요청함
	if(event.position == event.maxPosition) {
		if(!isLastPage) {
			if(!nowRequesting) {
				page++;
				getGridData();
			}
		}
	}
}

//검색
function search(){
	isLastPage = false;
	page = 1;
	sortValue = "";
	$("#count").html("0");
	$("#sessionId").val("");
	
	AUIGrid.destroy(myGridID);
	currentSituation_columnLayout();
	
	////grid setting
	createAUIGrid(columnLayout);
	//
	////get grid data
	getGridData();
}

//검색조건 초기화
function reset(){
	var locationDisplay = $("#locationDisplay").val();
	$("#searchForm")[0].reset();
	$("#locationDisplay").val(locationDisplay);
	
}

//필터 초기화
function resetFilter(){
    AUIGrid.clearFilterAll(myGridID);
}

function xlsxExport() {
	AUIGrid.setProperty(myGridID, "exportURL", getURLString("/common/xlsxExport"));
	
	 // 엑셀 내보내기 속성
	  var exportProps = {
			 postToServer : true,
	  };
	  // 내보내기 실행
	  AUIGrid.exportToXlsx(myGridID, exportProps);
}

function changeLoadingRows(selected){
	rows = parseInt($(selected).val());
	isLastPage = false;
	page = 1;
	sortValue = "";
	$("#count").html("0");
	$("#sessionId").val("");
	getGridData();
}

function deleteProcess(id){
	$("#" + id).val("");
	$("#" + id).trigger("change");
}

</script>
<div class="product">
	<!-- button -->
	<div class="seach_arm pt10 pb5">
		<div class="leftbt">
			<h4><img class="pointer" onclick="switchPopupDiv(this);" src="/Windchill/jsp/portal/images/minus_icon.png">&nbsp;${tl:getMessage('프로젝트 검색')}</h4>
		</div>
		<div class="rightbt">
			<%-- <button type="button" class="s_bt03" id="switchDetailBtn" onclick="switchDetailBtn();">${tl:getMessage('상세검색')}</button> --%>
			<button type="button" class="s_bt03" id="searchBtn" onclick="search();">${tl:getMessage('검색')}</button>
			<button type="button" class="s_bt05" id="resetBtn" onclick="reset();">${tl:getMessage('초기화')}</button>
		</div>
	</div>
	<!-- //button -->
	<!-- pro_table -->
	<div class="pro_table mr30 ml30">
		<form name="searchForm" id="searchForm">
			<input type="hidden" id="location" name="location" value="">
			<input type="hidden" id="sessionId" name="sessionId" value="">
			<table class="mainTable">
				<colgroup>
					<col style="width:15%">
					<col style="width:35%">
					<col style="width:15%">
					<col style="width:35%">
				</colgroup>	
				<tbody>
					<tr>
						<th scope="col">${tl:getMessage('프로젝트 유형')}</th>
						<td>
							<select class="multiSelect w10" id="productGubun" name="productGubun" style="height:20px;overflow-y: hidden;">
							</select>
						</td>
						<th scope="col">${tl:getMessage('상태')}</th>
						<td>
							<select class="multiSelect w10" id="state" name="state" multiple style="height:20px;overflow-y: hidden;">
							</select>
						</td>
					</tr>
					<tr>
						
					</tr>
					<tr>
						<th scope="col">${tl:getMessage('기준')}</th>
						<td colspan="3">
							<label class="no-drag"><input type="radio" onclick="javascript:changeCompare(this)" id="compareDate" name="compareDate" value="PLAN" checked>
							${tl:getMessage('계획일자')}</label>
							<span style="width: 10%; display: inline-block;"></span>
							<label class="no-drag"><input type="radio" onclick="javascript:changeCompare(this)"id="compareDate" name="compareDate" value="ESTI">
							${tl:getMessage('추정일자')}</label>
						</td>
					</tr>	
				</tbody>
			</table>
		</form>	
	</div>
	<!-- //pro_table -->
	<!-- button -->
	<div class="seach_arm pt5 pb5">
		<div class="leftbt">
			<span>
				<img class="" src="/Windchill/jsp/portal/images/t_icon.png"> ${tl:getMessage('검색 결과')} (<span id="count">0</span>/<span id="total">0</span>)
			</span>
		</div>
		<div class="rightbt">
			<img class="pointer mb5" id="favorite" data-type="false" data-oid="" onclick="add_favorite();" src="/Windchill/jsp/portal/images/favorites_icon_b.png" border="0"/>
			<select id="rows" name="rows" style="width:100px;" onchange="javascript:changeLoadingRows(this)">
				<option value="20">20</option>
				<option value="40">40</option>
				<option value="60">60</option>
				<option value="80">80</option>
				<option value="100">100</option>
			</select>
			<button type="button" class="s_bt03" onclick="resetFilter();">${tl:getMessage('필터 초기화')}</button>
			<%-- <button type="button" class="s_bt03" onclick="xlsxExport();">${tl:getMessage('엑셀 다운로드')}</button>
			<img class="pointer mb5" onclick="excelDown('searchForm', 'excelDownProject');" src="/Windchill/jsp/portal/icon/fileicon/xls.gif" border="0"> --%>
		</div>
	</div>
	<!-- //button -->
	<!-- table list-->
	<div class="table_list">
		<div class="list" id="grid_wrap" style="height:500px"></div>
	</div>
	<!-- //table list-->
</div>