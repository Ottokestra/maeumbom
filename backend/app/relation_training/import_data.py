"""
Excel/JSON 파일에서 시나리오 데이터를 읽어 DB에 저장하는 스크립트
"""
import sys
import argparse
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import openpyxl
from sqlalchemy.orm import Session

# Backend 경로 추가
backend_path = Path(__file__).parent.parent.parent
if str(backend_path) not in sys.path:
    sys.path.insert(0, str(backend_path))

from app.db.database import SessionLocal
from app.db.models import Scenario, ScenarioNode, ScenarioOption, ScenarioResult


class ScenarioImporter:
    """시나리오 데이터 Import 클래스"""
    
    def __init__(self, db: Session):
        self.db = db
        self.errors = []
    
    def read_json(self, file_path: Path) -> Dict:
        """JSON 파일 읽기"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
            
            # JSON 구조를 Excel 형식으로 변환
            data = {}
            
            # scenario -> scenarios 리스트로 변환
            if 'scenario' in json_data:
                scenario = json_data['scenario']
                # scenario_id가 없으면 1로 기본값 설정
                if 'scenario_id' not in scenario:
                    scenario['scenario_id'] = 1
                data['scenarios'] = [scenario]
            else:
                raise ValueError("'scenario' 필드가 없습니다")
            
            # nodes 변환
            if 'nodes' in json_data:
                nodes = json_data['nodes']
                # scenario_id 추가
                scenario_id = data['scenarios'][0]['scenario_id']
                for node in nodes:
                    node['scenario_id'] = scenario_id
                    # id 필드가 없으면 에러
                    if 'id' not in node:
                        raise ValueError("노드에 'id' 필드가 없습니다. JSON 파일은 노드 ID 기반 구조를 사용해야 합니다.")
                    # JSON 파일은 'text' 필드를 사용하므로 'situation_text'로 변환
                    if 'text' in node and 'situation_text' not in node:
                        node['situation_text'] = node['text']
                data['nodes'] = nodes
            else:
                raise ValueError("'nodes' 필드가 없습니다")
            
            # options 변환
            if 'options' in json_data:
                options = json_data['options']
                # scenario_id 추가
                scenario_id = data['scenarios'][0]['scenario_id']
                for option in options:
                    option['scenario_id'] = scenario_id
                    # text → option_text 매핑
                    if 'text' in option and 'option_text' not in option:
                        option['option_text'] = option['text']
                    # from_node_id와 to_node_id 사용 (새로운 구조)
                    if 'from_node_id' in option:
                        # 새로운 구조: from_node_id/to_node_id 사용
                        # to_node_id가 null이면 빈 문자열로 변환 (Excel 형식과 호환)
                        if option.get('to_node_id') is None:
                            option['to_node_id'] = ''
                        # None 유지 (나중에 처리)
                        # result_code가 null이면 빈 문자열로 변환
                        if option.get('result_code') is None:
                            option['result_code'] = ''
                    else:
                        # 기존 구조: node_step/next_step 사용 (하위 호환성)
                        # next_step이 null이면 빈 문자열로 변환
                        if option.get('next_step') is None:
                            option['next_step'] = ''
                        # result_code가 null이면 빈 문자열로 변환
                        if option.get('result_code') is None:
                            option['result_code'] = ''
                data['options'] = options
            else:
                raise ValueError("'options' 필드가 없습니다")
            
            # results 변환
            if 'results' in json_data:
                results = json_data['results']
                # scenario_id 추가
                scenario_id = data['scenarios'][0]['scenario_id']
                for result in results:
                    result['scenario_id'] = scenario_id
                data['results'] = results
            else:
                raise ValueError("'results' 필드가 없습니다")
            
            return data
            
        except Exception as e:
            raise Exception(f"JSON 파일 읽기 실패: {str(e)}")
    
    def read_excel(self, file_path: Path) -> Dict:
        """Excel 파일 읽기"""
        try:
            wb = openpyxl.load_workbook(file_path)
            
            # 필수 시트 확인
            required_sheets = ['scenarios', 'nodes', 'options', 'results']
            for sheet_name in required_sheets:
                if sheet_name not in wb.sheetnames:
                    raise ValueError(f"필수 시트가 없습니다: {sheet_name}")
            
            data = {}
            
            # 각 시트 읽기
            for sheet_name in required_sheets:
                ws = wb[sheet_name]
                rows = list(ws.values)
                
                if len(rows) < 2:  # 헤더 + 최소 1개 데이터
                    self.errors.append(f"{sheet_name} 시트에 데이터가 없습니다")
                    continue
                
                headers = rows[0]
                data[sheet_name] = []
                
                for i, row in enumerate(rows[1:], start=2):
                    # 빈 행 스킵
                    if all(cell is None or str(cell).strip() == '' for cell in row):
                        continue
                    
                    # 주석 행 스킵 (# 로 시작)
                    if row[0] and str(row[0]).strip().startswith('#'):
                        continue
                    
                    row_dict = {}
                    for header, value in zip(headers, row):
                        # 빈 값 처리
                        if value is None or str(value).strip() == '':
                            row_dict[header] = None
                        else:
                            row_dict[header] = value
                    
                    data[sheet_name].append(row_dict)
            
            return data
            
        except Exception as e:
            raise Exception(f"Excel 파일 읽기 실패: {str(e)}")
    
    def read_file(self, file_path: Path) -> Dict:
        """파일 확장자에 따라 Excel 또는 JSON 읽기"""
        if file_path.suffix.lower() == '.json':
            return self.read_json(file_path)
        elif file_path.suffix.lower() == '.xlsx':
            return self.read_excel(file_path)
        else:
            raise ValueError(f"지원하지 않는 파일 형식: {file_path.suffix}")
    
    def validate_data(self, data: Dict) -> bool:
        """데이터 검증"""
        is_valid = True
        
        # 시나리오 검증
        if not data.get('scenarios'):
            self.errors.append("시나리오 데이터가 없습니다")
            return False
        
        for scenario in data['scenarios']:
            if not scenario.get('scenario_id'):
                self.errors.append("scenario_id가 없습니다")
                is_valid = False
            if not scenario.get('title'):
                self.errors.append("title이 없습니다")
                is_valid = False
            if scenario.get('category') not in ['TRAINING', 'DRAMA']:
                self.errors.append(f"잘못된 category: {scenario.get('category')} (TRAINING 또는 DRAMA만 가능)")
                is_valid = False
        
        # 노드 검증
        if not data.get('nodes'):
            self.errors.append("노드 데이터가 없습니다")
            is_valid = False
        
        # 선택지 검증
        if not data.get('options'):
            self.errors.append("선택지 데이터가 없습니다")
            is_valid = False
        
        # 결과 검증
        if not data.get('results'):
            self.errors.append("결과 데이터가 없습니다")
            is_valid = False
        
        return is_valid
    
    def import_scenario(self, data: Dict, update_if_exists: bool = False) -> Tuple[bool, bool]:
        """시나리오 데이터를 DB에 저장
        
        Returns:
            (success, skipped): (성공 여부, 중복으로 스킵되었는지)
        """
        try:
            skipped = False
            for scenario_data in data['scenarios']:
                scenario_id_in_excel = scenario_data['scenario_id']
                
                # 기존 시나리오 확인
                existing = self.db.query(Scenario).filter(
                    Scenario.TITLE == scenario_data['title']
                ).first()
                
                if existing:
                    if not update_if_exists:
                        skipped = True
                        continue
                    else:
                        # 업데이트 모드: 기존 데이터 삭제
                        self.db.query(ScenarioOption).filter(
                            ScenarioOption.NODE_ID.in_(
                                self.db.query(ScenarioNode.ID).filter(
                                    ScenarioNode.SCENARIO_ID == existing.ID
                                )
                            )
                        ).delete(synchronize_session=False)
                        
                        self.db.query(ScenarioNode).filter(
                            ScenarioNode.SCENARIO_ID == existing.ID
                        ).delete()
                        
                        self.db.query(ScenarioResult).filter(
                            ScenarioResult.SCENARIO_ID == existing.ID
                        ).delete()
                        
                        self.db.delete(existing)
                        self.db.commit()
                
                # 시나리오 생성
                scenario = Scenario(
                    TITLE=scenario_data['title'],
                    TARGET_TYPE=scenario_data.get('target_type', 'general'),
                    CATEGORY=scenario_data['category'],
                    START_IMAGE_URL=scenario_data.get('start_image_url')
                )
                self.db.add(scenario)
                self.db.flush()  # ID 생성
                
                # 노드 생성
                nodes_for_scenario = [n for n in data['nodes'] if n['scenario_id'] == scenario_id_in_excel]
                
                # JSON 파일인지 Excel 파일인지 확인 (노드에 id 필드가 있는지 확인)
                is_json_format = len(nodes_for_scenario) > 0 and 'id' in nodes_for_scenario[0]
                
                if is_json_format:
                    # JSON 형식: 노드 ID 기반 매핑 ({node_id: db_node_id})
                    node_map = {}  # {node_id: db_node_id}
                    for node_data in nodes_for_scenario:
                        node = ScenarioNode(
                            SCENARIO_ID=scenario.ID,
                            STEP_LEVEL=node_data['step_level'],
                            SITUATION_TEXT=node_data['situation_text'],
                            IMAGE_URL=node_data.get('image_url')
                        )
                        self.db.add(node)
                        self.db.flush()
                        node_map[node_data['id']] = node.ID
                else:
                    # Excel 형식: step_level 기반 매핑 ({step_level: db_node_id})
                    node_map = {}  # {step_level: db_node_id}
                    for node_data in sorted(nodes_for_scenario, key=lambda x: x['step_level']):
                        node = ScenarioNode(
                            SCENARIO_ID=scenario.ID,
                            STEP_LEVEL=node_data['step_level'],
                            SITUATION_TEXT=node_data['situation_text'],
                            IMAGE_URL=node_data.get('image_url')
                        )
                        self.db.add(node)
                        self.db.flush()
                        node_map[node_data['step_level']] = node.ID
                
                # 결과 생성 (result_code -> result_id 매핑)
                result_map = {}  # {result_code: result_id}
                results_for_scenario = [r for r in data['results'] if r['scenario_id'] == scenario_id_in_excel]
                
                for result_data in results_for_scenario:
                    result = ScenarioResult(
                        SCENARIO_ID=scenario.ID,
                        RESULT_CODE=result_data['result_code'],
                        DISPLAY_TITLE=result_data['display_title'],
                        ANALYSIS_TEXT=result_data['analysis_text'],
                        ATMOSPHERE_IMAGE_TYPE=result_data.get('atmosphere_image_type'),
                        SCORE=result_data.get('score'),
                        IMAGE_URL=result_data.get('image_url')
                    )
                    self.db.add(result)
                    self.db.flush()
                    result_map[result_data['result_code']] = result.ID
                
                # 선택지 생성
                options_for_scenario = [o for o in data['options'] if o['scenario_id'] == scenario_id_in_excel]
                option_count = 0
                
                for option_data in options_for_scenario:
                    # JSON 형식인지 Excel 형식인지 확인
                    if is_json_format and 'from_node_id' in option_data:
                        # JSON 형식: from_node_id/to_node_id 사용
                        from_node_id = option_data['from_node_id']
                        if from_node_id not in node_map:
                            self.errors.append(f"존재하지 않는 from_node_id: {from_node_id}")
                            continue
                        
                        current_node_id = node_map[from_node_id]
                        
                        # to_node_id 또는 result_code 중 하나는 있어야 함
                        next_node_id = None
                        result_id = None
                        
                        if option_data.get('to_node_id'):
                            to_node_id = option_data['to_node_id']
                            if to_node_id not in node_map:
                                self.errors.append(f"존재하지 않는 to_node_id: {to_node_id}")
                                continue
                            next_node_id = node_map[to_node_id]
                        elif option_data.get('result_code'):
                            result_code = option_data['result_code']
                            if result_code not in result_map:
                                self.errors.append(f"존재하지 않는 result_code: {result_code}")
                                continue
                            result_id = result_map[result_code]
                        else:
                            self.errors.append(f"to_node_id 또는 result_code 중 하나는 필수입니다")
                            continue
                    else:
                        # Excel 형식: node_step/next_step 사용
                        node_step = option_data['node_step']
                        if node_step not in node_map:
                            self.errors.append(f"존재하지 않는 node_step: {node_step}")
                            continue
                        
                        current_node_id = node_map[node_step]
                        
                        # next_step 또는 result_code 중 하나는 있어야 함
                        next_node_id = None
                        result_id = None
                        
                        if option_data.get('next_step'):
                            next_step = option_data['next_step']
                            if next_step not in node_map:
                                self.errors.append(f"존재하지 않는 next_step: {next_step}")
                                continue
                            next_node_id = node_map[next_step]
                        elif option_data.get('result_code'):
                            result_code = option_data['result_code']
                            if result_code not in result_map:
                                self.errors.append(f"존재하지 않는 result_code: {result_code}")
                                continue
                            result_id = result_map[result_code]
                        else:
                            self.errors.append(f"next_step 또는 result_code 중 하나는 필수입니다")
                            continue
                    
                    option = ScenarioOption(
                        NODE_ID=current_node_id,
                        OPTION_TEXT=option_data['option_text'],
                        OPTION_CODE=option_data['option_code'],
                        NEXT_NODE_ID=next_node_id,
                        RESULT_ID=result_id
                    )
                    self.db.add(option)
                    option_count += 1
                
            self.db.commit()
            return (True, skipped)
            
        except Exception as e:
            self.db.rollback()
            self.errors.append(f"DB 저장 실패: {str(e)}")
            import traceback
            traceback.print_exc()
            return (False, False)


def import_file(file_path: Path, update: bool = False):
    """단일 파일 import"""
    db = SessionLocal()
    try:
        importer = ScenarioImporter(db)
        
        # 파일 읽기 (Excel 또는 JSON)
        try:
            data = importer.read_file(file_path)
        except Exception as e:
            import traceback
            print(f"❌ {file_path.name}: 파일 읽기 실패")
            print(f"  에러: {str(e)}")
            traceback.print_exc()
            return False
        
        # 데이터 검증
        if not importer.validate_data(data):
            print(f"❌ {file_path.name}: 데이터 검증 실패")
            for error in importer.errors:
                print(f"  - {error}")
            return False
        
        # DB에 저장
        success, skipped = importer.import_scenario(data, update_if_exists=update)
        
        if success:
            if skipped:
                print(f"⏭️  {file_path.name}: 이미 존재하는 시나리오 (스킵)")
                return None  # 스킵됨
            else:
                print(f"✅ {file_path.name}: Import 성공")
                return True
        else:
            print(f"❌ {file_path.name}: Import 실패")
            for error in importer.errors:
                print(f"  - {error}")
            return False
            
    except Exception as e:
        import traceback
        print(f"❌ {file_path.name}: 예상치 못한 에러 발생")
        print(f"  에러: {str(e)}")
        traceback.print_exc()
        return False
    finally:
        db.close()


def import_all(data_dir: Path, update: bool = False, clear: bool = False):
    """data 폴더의 모든 Excel/JSON 파일 import"""
    print(f"\n{'='*50}")
    print(f"[시나리오 Import 시작]")
    print(f"  데이터 폴더: {data_dir}")
    print(f"  업데이트 모드: {update}")
    print(f"  기존 데이터 삭제: {clear}")
    print(f"{'='*50}")
    
    if clear:
        db = SessionLocal()
        try:
            print("[INFO] 기존 시나리오 데이터 삭제 중...")
            db.query(ScenarioOption).delete()
            db.query(ScenarioNode).delete()
            db.query(ScenarioResult).delete()
            db.query(Scenario).delete()
            db.commit()
            print("[INFO] 기존 데이터 삭제 완료")
        except Exception as e:
            import traceback
            print(f"[ERROR] 기존 데이터 삭제 실패: {str(e)}")
            traceback.print_exc()
            db.rollback()
        finally:
            db.close()
    
    # Excel 파일
    excel_files = list(data_dir.glob('*.xlsx'))
    excel_files = [f for f in excel_files if not f.name.startswith('~') and f.name != 'template.xlsx']
    
    # JSON 파일
    json_files = list(data_dir.glob('*.json'))
    json_files = [f for f in json_files if f.name != 'template.json']
    
    all_files = excel_files + json_files
    
    if not all_files:
        print("[INFO] Import할 파일이 없습니다.")
        print(f"{'='*50}\n")
        return
    
    print(f"[INFO] 발견된 파일: Excel {len(excel_files)}개, JSON {len(json_files)}개")
    
    success_count = 0
    skip_count = 0
    fail_count = 0
    for file_path in all_files:
        result = import_file(file_path, update)
        if result is True:
            success_count += 1
        elif result is None:
            skip_count += 1
        elif result is False:
            fail_count += 1
    
    print(f"\n{'='*50}")
    print(f"[시나리오 Import 완료]")
    print(f"✅ 성공: {success_count}개 파일")
    if skip_count > 0:
        print(f"⏭️  스킵: {skip_count}개 파일 (중복 - 이미 DB에 존재)")
    if fail_count > 0:
        print(f"❌ 실패: {fail_count}개 파일")
    print(f"{'='*50}\n")


def main():
    parser = argparse.ArgumentParser(description='시나리오 데이터 Import')
    parser.add_argument('file', nargs='?', help='Import할 Excel/JSON 파일 경로')
    parser.add_argument('--all', action='store_true', help='data 폴더의 모든 파일 import')
    parser.add_argument('--update', action='store_true', help='기존 시나리오 업데이트')
    parser.add_argument('--clear', action='store_true', help='기존 데이터 삭제 후 import')
    
    args = parser.parse_args()
    
    data_dir = Path(__file__).parent / 'data'
    
    if args.all:
        import_all(data_dir, update=args.update, clear=args.clear)
    elif args.file:
        file_path = Path(args.file)
        if not file_path.exists():
            print(f"❌ 파일을 찾을 수 없습니다: {file_path}")
            return
        import_file(file_path, update=args.update)
    else:
        # 기본: data 폴더의 모든 파일 import
        import_all(data_dir, update=args.update, clear=args.clear)


if __name__ == '__main__':
    main()

