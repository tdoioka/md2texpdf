#!/usr/bin/env python3
from pandocfilters import toJSONFilter, RawBlock
from typing import List, Dict, Union, Any, Optional, Callable, cast
from bs4 import BeautifulSoup, Tag
import re

# import logging


def latex(xx: str) -> RawBlock:
    return RawBlock("latex", xx)


class Pos(object):
    def __init__(self, pos: Optional["Pos"] = None) -> None:
        self.x: int = pos.x if pos else 0
        self.y: int = pos.y if pos else 0

    def __str__(self) -> str:
        return "({},{})".format(self.x, self.y)


class Cell(object):
    def __init__(self, pos: Pos, data: Tag) -> None:
        self.pos = Pos(pos)
        self.data = data

    def __str__(self) -> str:
        return "p:{} d:{}".format(str(self.pos), str(self.data))


class Table(object):
    def __init__(self) -> None:
        # Permutes matrices in terms of data structure.
        # That is, the first dimension is the column and the second dimension is the row.
        # self.table[x][y]
        self.__table: List[List[Optional[Cell]]] = [[None]]
        self.cur = Pos()

    @property
    def width(self) -> int:
        return len(self.__table)

    @property
    def height(self) -> int:
        return len(self.__table[0])

    def insertcell(self, cell: Cell) -> None:
        # insert cell
        while True:
            if self.cur.x < len(self.__table):
                if self.cur.y < len(self.__table[self.cur.x]):
                    if self.__table[self.cur.x][self.cur.y] is None:
                        self.__table[self.cur.x][self.cur.y] = cell
                        break
                    self.cur.x += 1
                    cell.pos.x = self.cur.x
                else:
                    self.__table[self.cur.x].append(None)
            else:
                self.__table.append([None])

    def insertrow(self, xx: int, yy: int, cell: Cell) -> None:
        while True:
            if xx < len(self.__table):
                if yy < len(self.__table[xx]):
                    self.__table[xx][yy] = cell
                    break
                else:
                    self.__table[xx].append(None)
            else:
                self.__table.append([None])

    def push(self, col: Tag) -> None:
        cell = Cell(self.cur, col)
        colspan = int(col.get("colspan") or 1)
        rowspan = int(col.get("rowspan") or 1)
        for _ in range(colspan):
            self.insertcell(cell)
            for cnt in range(1, rowspan):
                self.insertrow(self.cur.x, self.cur.y + cnt, cell)
            self.cur.x += 1

    def newline(self) -> None:
        self.cur.x = 0
        self.cur.y = self.cur.y + 1

    def get(self, x: int, y: int) -> Optional[Cell]:
        if x < len(self.__table):
            if y < len(self.__table[x]):
                return self.__table[x][y]
        return None

    def __str__(self) -> str:
        ss: str = "["
        for yy in self.__table:
            ss = ss + "["
            for xx in yy:
                ss = ss + str(xx) + ","
            ss = ss[:-1] + "]"
        ss = ss + "]"
        return "cur:{} table:{}".format(str(self.cur), ss)


class TableStack(object):
    def __init__(self) -> None:
        """ List of collected html table strings """
        self.htmltable: List[str] = list()
        """
        if found <table>  : False -> True
        if found </table> : True -> False
        """
        self.collecting = False

    def iscollecting(self) -> bool:
        """ is Collecting table text """
        return self.collecting

    def push(self, tag: str) -> "TableStack":
        """ Parse html {tag}"""
        if re.match(r"<table[ >]", str(tag)):
            if self.collecting:
                raise ValueError(
                    "Unterminated **** '<table>' found, Abort. stacked data : {}".format(
                        self.htmltable
                    )
                )
            self.collecting = True
            self.htmltable.clear()
            self.htmltable.append(tag)
        elif re.match(r"</table[ >]", str(tag)):
            self.htmltable.append(tag)
            self.collecting = False
        else:
            self.htmltable.append(tag)
        return self

    def latex(self) -> Optional[List[RawBlock]]:
        """When closed table tag. print data, and pop all"""
        if self.collecting:
            return []
        # Put latex format table.
        ll: List[str] = list()
        soup = BeautifulSoup("".join(self.htmltable), features="html.parser")
        trs = soup.find_all("tr")
        # Build table
        tbl = Table()
        for tr in trs:
            for col in tr.contents:
                tbl.push(col)
            tbl.newline()
        ll.append(
            "\\begin{center} \\begin{tabularx}{1.0 \\linewidth}{"
            + "|l" * (tbl.width -1)
            + "|X|} \\hline\n"
        )
        for y in range(tbl.height):
            line = list()
            for x in range(tbl.width):
                cell = tbl.get(x, y)
                # logging.warning('{} {} {}'.format(x,y,cell))
                if cell and cell.pos.x == x and cell.pos.y == y:
                    colspan = int(cell.data.get("colspan") or 1)
                    if 1 < colspan:
                        line.append(
                            "\\multicolumn{{{}}}{{c|}}{{{}}}".format(colspan, cell.data.string)
                        )
                    else:
                        line.append(cell.data.string)
                elif cell and cell.pos.y != y:
                    line.append(" ")
            # logging.warning('{},{},{}'.format(tbl.height, tbl.width, line))

            ll.append("{} \\\\ \\hline\n".format(" & ".join(line)))
        ll.append("\\end{tabularx} \\end{center}\n")
        return [latex("".join(ll))]


TPlainV = List[Dict[str, str]]
TRawBlockV = List[str]
TValue = Union[TPlainV, TRawBlockV]


def filter(key: str, value: TValue, format: str, meta: Dict[Any, Any]) -> Optional[Any]:
    if ts.iscollecting() or (key == "RawBlock" and value[0] == "html"):
        keytbl: Dict[str, Callable[[TValue], str]] = {
            "Plain": (lambda x: cast(TPlainV, x)[0]["c"]),
            "RawBlock": (lambda x: cast(TRawBlockV, x)[1]),
        }
        ff = keytbl.get(key)
        vv: Optional[str] = None
        if ff:
            vv = ff(value)
            return ts.push(vv).latex()
    return None


if __name__ == "__main__":
    ts = TableStack()
    toJSONFilter(filter)
