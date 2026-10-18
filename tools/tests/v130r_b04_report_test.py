"""Guard against mixing deferred settlement upgrades into battle HP."""
import copy
import unittest
from v130r_b04_report import combat_hp_record


class CombatHpRecordTest(unittest.TestCase):
    stages={
        'stage_03_keep': {'index':3,'throne_max_hp':2100},
        'stage_04_citadel': {'index':4,'throne_max_hp':2500},
    }

    def entry(self):
        return {'payload':{'game_state':{'demon_lord_hp':1363,'demon_lord_max_hp':2100},'world':{'castle_art_stage':'stage_03_keep'}}}

    def post_settlement(self):
        return {'hp':1763,'max_hp':2500,'win':True,'settlement':{'metrics':{'demon_lord_hp':1763},'lines':['evolution (castle_evolution_stage_04)']}}

    def test_deferred_result_is_independent_of_the_frame_boundary(self):
        before={'hp':1363,'max_hp':2100,'win':True}
        after=self.post_settlement()
        original=copy.deepcopy(after)
        a=combat_hp_record(before,self.entry(),self.stages)
        b=combat_hp_record(after,self.entry(),self.stages)
        self.assertEqual((a['hp'],a['max_hp']),(b['hp'],b['max_hp']))
        self.assertEqual((b['recorded_hp'],b['recorded_max_hp'],b['settlement_upgrade_delta']),(1763,2500,400))
        self.assertEqual(after,original)

    def test_combat_damage_and_losses_are_retained(self):
        for hp,win in [(931,True),(0,False)]:
            row={'hp':hp,'max_hp':2100,'win':win}
            value=combat_hp_record(row,self.entry(),self.stages)
            self.assertEqual((value['hp'],value['max_hp']),(hp,2100))
            self.assertNotIn('settlement_upgrade_delta',value)

    def test_undeclared_hp_changes_are_rejected(self):
        for field,value in [('max_hp',2600),('win',False),('hp',399)]:
            with self.subTest(field=field):
                row=self.post_settlement();row[field]=value
                with self.assertRaises(AssertionError):
                    combat_hp_record(row,self.entry(),self.stages)

    def test_both_upgrade_event_and_matching_settlement_are_required(self):
        for missing in ['event','matching_hp']:
            with self.subTest(missing=missing):
                row=self.post_settlement()
                if missing=='event':row['settlement']['lines']=[]
                else:row['settlement']['metrics']['demon_lord_hp']=1363
                with self.assertRaises(AssertionError):
                    combat_hp_record(row,self.entry(),self.stages)


if __name__=='__main__':unittest.main()
